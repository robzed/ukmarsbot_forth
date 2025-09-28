\ * Project:    UKMARS Gemini
\ * File:       GeminiBasicLineFollower.f
\ * Language:   Zeptoforth Forth
\ * Version:    1.0
\ * Author:     Rob Probin, based on Ian Butterworth's Python code
\ * Created:    16 July 2025
\ * Description:
\ *     Simple example line following code for the UKMARS Gemini platform with PiPico.
\ *     This code does not require that encoders are available.
\ *     Logging information is broadcast on UART0 for transmission over bluetooth connected to J2.
\ *     It is not necessary to have the bluetooth module installed the robot will run but 
\ *     without the bluetooth serial link, logging information will not be available.
\ *
\ * -----
\ * MIT License
\ *
\ * Copyright (c) 2025 Rob Probin,  Ian Butterworth
\ *
\ * Permission is hereby granted, free of charge, to any person obtaining a copy of
\ * this software and associated documentation files (the "Software"), to deal in
\ * the Software without restriction, including without limitation the rights to
\ * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
\ * of the Software, and to permit persons to whom the Software is furnished to do
\ * so, subject to the following conditions:
\ *
\ * The above copyright notice and this permission notice shall be included in all
\ * copies or substantial portions of the Software.
\ *
\ * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
\ * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
\ * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
\ * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
\ * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
\ * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
\ * SOFTWARE.

\ Additions to Basic Line follower examples are
\ =============================================
\

\ from machine import Pin,ADC,PWM,UART
adc import
pin import
pwm import
led import
timer import


\ uart=UART(0, 115200)	\ Select baudrate for bluetooth connection - choose the fastest reliable value
\                       \ This code outputs calibration data and running logging information over UART0
28 constant leftsensor  \ ADC(28)
26 constant rightsensor \ ADC(26)
27 constant radiussensor \ ADC(27)
27 constant startsensor \ ADC(27) connected to same input as radius

22 constant emitter \ Pin(22,Pin.OUT)
18 constant radiusEmitter \ Pin(18,Pin.OUT)

\ GP25 on Raspberry Pi Pico and Pico 2, on the Pico W and Pico 2 W it's on the Wi-Fi chip...
variable board_pico_w
: onBoardLED.value ( value -- )
    board_pico_w @ if
        my-cyw43-net swap pico-w-led!
    else
        green swap led!
    endif
;

12 constant leftSensorLED \ Pin(21,Pin.OUT)
20 constant centreSensorLED \ Pin(20,Pin.OUT)
19 constant rightSensorLED \ Pin(19,Pin.OUT)
10 constant leftMezzLED \ Pin(10,Pin.OUT)
11 constant rightMezzLED \ Pin(11,Pin.OUT)

3 constant leftRev = PWM(Pin(3))
leftRev.freq(2000)
2 constant leftFwd = PWM(Pin(2))
leftFwd.freq(2000)
4 constant rightRev = PWM(Pin(4))
rightRev.freq(2000)
5 constant rightFwd = PWM(Pin(5))
rightFwd.freq(2000)
15 constant leftButton \ Pin(15, Pin.IN, Pin.PULL_UP)
14 constant rightButton \ Pin(14, Pin.IN, Pin.PULL_UP)

\ general helpers
: >> rshift ;
: << lshift ;

\ helpers for GPIO pin setup
: make_output0 ( pin -- ) dup output-pin false swap pin! ;
: make_input_pullup ( pin -- ) dup input-pin pull-up-pin ;
: >pwm-slice ( pin -- pwm-slice )  1 >>  7 and ;
: pwm-compare! ( value pin -- ) dup >pwm-slice swap 1 and if pwm-counter-compare-b! else pwm-counter-compare-a! then ; 

: pwm-duty-u8 ( u8 pin -- ) pwm-compare! ;

: disable_pwm ( pin -- )
    dup  input-pin
    >pwm-slice bit disable-pwm
;


: setup_pwm { pin -- }

  \ disable before setup
  pin disable_pwm

  \ Here we set our PWM slice to be free-running, rather than gated or a counter
  pin >pwm-slice free-running-pwm

  \ Here we set phase correction off
  false pin >pwm-slice pwm-phase-correct!

  \ Freq-PWM = Fsys / period
  \ period = (TOP+1) * (CSR_PH_CORRECT+1) + (DIV_INT + DIV_FRAC/16)
  \ e.g. 125 MHz / 16.0 = 7.8125 MHz rate base rate
  \ divider is 8 bit integer part, 4 bit fractional part
  \ Since phase correct is false/0, we only need to worry about TOP and Divider

  \ As the system clock is 125 MHz, this gives us a clock of 125000000/(15*(254+1)) = ~32 kHz
  \ You can calculate the actual clock with print-actual_frequency (out of sounds.fth)
  \ You could theoretically use calculate_closest_dividers (out of sounds.fth) but
  \ this uses a different top count, which we don't want here.
  0 15 pin >pwm-slice pwm-clock-div!


  \ 12 500 000 / (120*(254+1)) = ~ 4 KHz
  \ 0 120 pin >pwm-slice pwm-clock-div!

  \ 125*10^6 / (240*(254+1)) = ~ 2 KHz (actually 2042.48366013 Hz)
  0 240 pin >pwm-slice pwm-clock-div!

  \ set top counters - since we want 0 to be no turn on, and 255 to be no turn 
  \ off, this is 254.
  \ See this from RP2040 datasheet: 
  \   "A CC value of 0 will produce a 0% output, i.e. the output signal is 
  \    always low. A CC value of TOP + 1 (i.e. equal to the period, in 
  \    non-phase-correct mode) will produce a 100% output. For example, 
  \    if TOP is programmed to 254, the counter will have a period of 255 cycles, 
  \    and CC values in the range of 0 to 255 inclusive will produce duty cycles 
  \    in the range 0% to 100% inclusive. 
  \ 
  \    Glitch-free output at 0% and 100% is important e.g. to avoid switching 
  \    losses when a MOSFET is controlled at its minimum and maximum current levels."
  254 pin >pwm-slice pwm-top!

  \ set current PWM value
  0 pin pwm-compare!

  \ make sure counter is zero
  0 pin >pwm-slice pwm-counter!

  pin  output-pin
  false pin  pin!

  pin pwm-pin
  0 pin pwm-compare!

  pin >pwm-slice bit enable-pwm
;

: adc_read ( pin -- value )
    pin-adc-chan default-adc adc@
;
: adc_read_u16 ( pin -- value )
    adc_read
    adc-min - 
    65535
    adc-max adc-min -  \ range
    */
;

: init-GPIO ( -- )
    \ look for the driver to see if a Pico W
    s" my-cyw43-net" find board_pico_w !

    \ ADC setup
    default-adc enable-adc
    default-adc leftsensor adc-pin
    default-adc rightsensor adc-pin
    default-adc radiussensor adc-pin
    default-adc startsensor adc-pin

    emitter make_output0
    radiusEmitter make_output0

    leftSensorLED make_output0
    centreSensorLED make_output0
    rightSensorLED make_output0
    leftMezzLED make_output0
    rightMezzLED make_output0
    
    leftRev setup_pwm
    leftFwd setup_pwm
    rightRev setup_pwm
    rightFwd setup_pwm

    leftButton make_input_pullup
    rightButton make_input_pullup
;

\ Robot states
1 constant WAITING_CALIBRATION
2 constant CALIBRATING
3 constant WAITING_START_PB
4 constant PRE_START_MARKER
5 constant RUNNING
6 constant STOPPING
7 constant HALTED

variable robotState
variable loopCounter \ Used to tag logged data and detect any lack of continuity in the logging
variable loopPeriod  \ Delay between control loop iterations in mS - control loop frequency will be lower due to the time taken to execute the code consider aligning with Pico clock

2variable f_error       \ Delay should be as small as possible but give enough time for the logging data transmission over bluetooth
2variable f_oldError
2variable f_change
2variable f_kp
2variable f_kd       \ differential constant defined as the multiplier of change in error per second
2variable f_kdLoop   \ The actual constant applied in the loop needs to scale for the duration of the loop
2variable f_speed     \ between 0 and 100
2variable f_pErrorTerm
2variable f_dErrorTerm

\ Global variables to make readings available after the update function has run
variable leftSensorUnlit
variable rightSensorUnlit
variable radiusSensorUnlit
variable startSensorUnlit

variable leftSensorLit
variable rightSensorLit
variable radiusSensorLit
variable startSensorLit

variable leftSensorValue
variable rightSensorValue
variable radiusSensorValue
variable startSensorValue

: init-state
    WAITING_CALIBRATION robotState !
    0 loopCounter !  \ Used to tag logged data and detect any lack of continuity in the logging
    4 loopPeriod !   \ Delay between control loop iterations in mS - control loop frequency will be lower due to the time taken to execute the code consider aligning with Pico clock

    0. f_error 2!        \ Delay should be as small as possible but give enough time for the logging data transmission over bluetooth
    0. f_oldError 2!
    0. f_change 2!
    2.5 f_kp 2!
    3000. f_kd 2!   \ differential constant defined as the multiplier of change in error per second
    f_kd loopPeriod s>f f* 1000. f/ f_kdLoop !   \ The actual constant applied in the loop needs to scale for the duration of the loop
    20. f_speed 2!                             \ between 0 and 100
    0. f_pErrorTerm 2!
    0. f_dErrorTerm 2!

    \ Global variables to make readings available after the update function has run
    0 leftSensorUnlit !
    0 rightSensorUnlit !
    0 radiusSensorUnlit !
    0 startSensorLit !

    0 leftSensorLit !
    0 rightSensorLit !
    0 radiusSensorLit !
    0 startSensorLit !

    0 leftSensorValue !
    0 rightSensorValue !
    0 radiusSensorValue !
    0 startSensorValue !
;

: readSensors ( -- ) 
    \ Values are derived by subtracting the lit value of a sensor from the unlit value 
    \ Unlit raw readings close to 65000 indicate good separation from ambient light
    \ The radius and start/finish sensors are multiplexed onto the same ADC channel using separate emitters
    \ The UKMARS line follower sensor board gives high value readings for low incident light and low value readings for high incident light
    
    0 emitter pin!
    0 radiusEmitter pin!

    leftsensor adc_read_u16 leftSensorUnlit !
    rightsensor adc_read_u16 rightSensorUnlit !
    startsensor adc_read_u16 startSensorUnlit !
    radiussensor adc_read_u16 radiusSensorUnlit !

    1 emitter pin!
    15. delay-us
    leftsensor adc_read_u16 leftSensorLit !
    rightsensor adc_read_u16 rightSensorLit !
    startsensor adc_read_u16 startSensorLit !
    0 emitter pin!

    1 radiusEmitter pin!
    15. delay-us
    radiussensor adc_read_u16 radiusSensorLit !
    0 radiusEmitter pin!

    leftSensorUnlit @ leftSensorLit @ - leftSensorValue !
    rightSensorUnlit @ rightSensorLit @ - rightSensorValue !
    startSensorUnlit @ startSensorLit @ - startSensorValue !
    radiusSensorUnlit @ radiusSensorLit @ - radiusSensorValue !
;

\ Set the motor pwm duty cycle from required speed expressed as a percentage 0-100
: leftMotor { speed -- }
    speed 0< if
        speed negate to speed
        speed 100 > if
            100 to speed
        then
        speed 25 * \ dutyCycle 0-255
        0 leftFwd pwm-duty-u8
        leftRev pwm-duty-u8
    else:
        speed 100 > if
            100 to speed
        then
        speed 25 * \ dutyCycle 0-255
        0 leftRev pwm-duty-u8
        leftFwd pwm-duty-u8
    then
;

: rightMotor { speed -- }
    speed 0< if
        speed negate to speed
        speed 100 > if
            100 to speed
        then
        speed 25 * \ dutyCycle 0-255
        0 rightFwd pwm-duty-u8
        rightRev pwm-duty-u8
    else:
        speed 100 > if
            100 to speed
        then
        speed 25 * \ dutyCycle 0-255
        0 rightRev pwm-duty-u8
        rightFwd pwm-duty-u8
;

: stopMotors ( -- )
    0 rightRev pwm-duty-u8
    0 rightFwd pwm-duty-u8
    0 leftRev pwm-duty-u8
    0 leftFwd pwm-duty-u8
;

\ --------------------------------------------
\ calibration caps and collars
variable leftMax
variable leftMin
variable rightMax
variable rightMin
variable radiusMax
variable radiusMin
variable startMax
variable startMin

variable radiusLeadingEdge
variable radiusTrailingEdge
variable startLeadingEdge
variable startTrailingEdge

: init-calibration
    0 leftMax !
    65535 leftMin !
    0 rightMax !
    65535 rightMin !
    0 radiusMax !
    65535 radiusMin !
    0 startMax !
    65535 startMin !

    0 radiusLeadingEdge !
    0 radiusTrailingEdge !
    0 startLeadingEdge !
    0 startTrailingEdge !
;

\ update the maximum and minimum reflected values
: calibrateSensors ( -- )
    leftSensorValue leftMax > if leftSensorValue leftMax !
    leftSensorValue leftMin < if leftSensorValue leftMin !
    rightSensorValue rightMax > if rightSensorValue rightMax !
    rightSensorValue rightMin < if rightSensorValue rightMin !
    radiusSensorValue radiusMax > if radiusSensorValue radiusMax !
    radiusSensorValue radiusMin < if radiusSensorValue radiusMin !
    startSensorValue startMax > if startSensorValue startMax !
    startSensorValue startMin < if startSensorValue startMin !
;

\ global flags for marker detection
variable sfLeadingEdgeDetected
variable sfTrailingEdgeDetected
variable sfTrigger
variable radiusLeadingEdgeDetected
variable radiusTrailingEdgeDetected
variable radiusTrigger
variable crossoverDetected

: initialiseMarkerFlags ( -- )
    false sfLeadingEdgeDetected !
    false sfTrailingEdgeDetected !
    false sfTrigger !
    false radiusLeadingEdgeDetected !
    false radiusTrailingEdgeDetected !
    false radiusTrigger !
    false crossoverDetected !
;

: checkMarkers ( -- )

    sfLeadingEdgeDetected @ if                                     \ already detected leading edge of start/finish marker
        radiusLeadingEdgeDetected @ if
            true crossoverDetected !
        startSensorValue @ startTrailingEdge @ < if                  \ trailing edge detected
            true sfTrailingEdgeDetected !
            crossoverDetected @ if                                 \ ignore crossovers
                false sfLeadingEdgeDetected !
                false sfTrailingEdgeDetected !
                false sfTrigger !
                radiusLeadingEdgeDetected not if                  \ if the radius detection has been cleared clear the crossover flag
                    false crossoverDetected !
            else
                true sfTrigger !
                false sfLeadingEdgeDetected !
                false sfTrailingEdgeDetected !
            then
        else
            \ pass
        then                                                    \ Leading edge detected and sensor above trailing edge threshold so do nothing
    else:                                               \  No SF leading edge previously detected so check for leading edge
        startSensorValue @ startLeadingEdge @ > if
            true sfLeadingEdgeDetected !
            radiusLeadingEdgeDetected @ if
                true crossoverDetected !
        else                                           \ No leading edge detected so do nothing
            \ pass
        then

    radiusLeadingEdgeDetected @ if                                 \ already detected leading edge of radius marker
        sfLeadingEdgeDetected @ if
            true crossoverDetected !
        radiusSensorValue @ radiusTrailingEdge @ < if                \ trailing edge detected
            true radiusTrailingEdgeDetected !
            crossoverDetected @ if
                false radiusLeadingEdgeDetected !
                false radiusTrailingEdgeDetected !
                false radiusTrigger !
                sfLeadingEdgeDetected @ not if                     \ if the start finish detection has been cleared clear the crossover flag
                    false crossoverDetected !                      \ otherwise leave it set to allow start finish to ignore crossover and clear
            else
                true radiusTrigger !                               \ trailing edge detected and no crossover so register radius
                false radiusLeadingEdgeDetected !
                false radiusTrailingEdgeDetected !
            then
        else                                                       \ Leading edge detected and sensor above trailing edge threshold so do nothing
            \ pass
        then
    else                                              \ No Radius leading edge already detected so check for leading edge
        radiusSensorValue @ radiusLeadingEdge @ > if
            true radiusLeadingEdgeDetected !
            sfLeadingEdgeDetected @ if
                true crossoverDetected !                          \ s/f leading edge also detected so must be a crossover
            then
    then
;


: displayCalibrationHeader ( -- )
    ." loopCounter, leftMin, leftMax, rightMin, rightMax, radiusMin, radiusMax, startMin, startMax"
    cr

: displayCalibration ( -- )
    loopCounter @ .
    " ,"
    leftMin @ .
    " ,"
    leftMax @ .
    " ,"
    rightMin @ .
    " ,"
    rightMax @ .
    " ,"
    radiusMin @ .
    " ,"
    radiusMax @ .
    " ,"
    startMin @ .
    " ,"
    startMax @ .
    cr

2variable f_lsensorCal
2variable f_rsensorCal

variable leftSpeed
variable rightSpeed

: displayLogging ( -- )
    loopCounter @ .
    " ,"
    f_lsensorCal 2@ 2 f.n
    " ,"
    f_rsensorCal 2@ 2 f.n
    " ,"
    f_error 2@ 2 f.n
    " ,"
    f_change 2@ 2 f.n
    " ,"
    f_pErrorTerm 2@ 2 f.n
    " ,"
    f_dErrorTerm 2@ 2 f.n
    " ,"
    leftSpeed @ .
    " ,"
    rightSpeed @ .
    " ,"
    cr
;

: greeting ( -- )
    ." Gemini Basic Line Follower : Hello" cr 
    ." speed="
    speed 2@ f.
    ."  kp="
    f_kp 2@ f.
    ."  kd="
    f_kd 2@ f.
    ."  kdLoop="
    f_kdLoop 2@ f.
    cr
;

: displayThresholds ( -- )
    ." radiusLeading="
    radiusLeadingEdge @ .
    ."  radiusTrailing="
    radiusTrailingEdge @ .
    ."  startLeading="
    startLeadingEdge @ .
    ."  startTrailing="
    startTrailingEdge @ .
    cr
;

\ --------------------------------------------
\ Main Program

variable robotCalibrated
variable robotRunning
variable startCount
25 constant calibrate_pwm_value \ PWM to use during calibration

: do_calibrate ( -- )
    robotCalibrated @ false = if 
        begin rightButton pin@ 1 =
        while 	\ Slow Blink LED until Right button pressed
            \ This is a good time to establish a serial connection if using an HC05/06 bluetooth module
            1 onBoardLED.value
            300 ms
            0 onBoardLED.value
            300 ms
        repeat

        1 rightMezzLED pin!    \ signal button detected with LED
        CALIBRATING robotState !
        greeting
        ." Calibrating robot"
        cr
        displayCalibrationHeader
        250 ms
        0 rightMezzLED pin!

        loopCounter @ startCount ! 
        calibrate_pwm_value leftMotor
        calibrate_pwm_value negate rightMotor
        begin loopCounter startCount - 200 < 
        while
            1 loopCounter +!
            readSensors
            calibrateSensors
            displayCalibration
            5 ms
        repeat
        stopMotors

        radiusMax @ - radiusMin @ - 2/
        radiusMin @ +  radiusLeadingEdge !  \ Marker leading and trailing edge thresholds for marker detection
        radiusMax @ - radiusMin @ -  3 /
        radiusMin @ + radiusTrailingEdge ! \ with hysteresis

        startMax @ - startMin @ - 2/
        startMin @ +  startLeadingEdge !
        startMax @ - startMin @ -  3 /
        startMin @ + startTrailingEdge !

        displayThresholds
        10 ms
        true robotCalibrated !
;

: do_run ( -- )
    \ use left button to start
    WAITING_START_PB robotState !
    begin leftButton pin@  1 = 	\ Fast Blink LED until Left button pressed
    while
        1 onBoardLED.value
        100 ms
        0 onBoardLED.value
        100 ms
    repeat
    1 leftMezzLED pin!        \ signal button detected with LED
    0 leftSensorLED pin!      \ clear LEDs used to signal significant steering adjustment
    0 rightSensorLED pin!
    ." Starting robot"
    cr
    true robotRunning !
    PRE_START_MARKER robotState !
    0 f_error 2!
    0 f_oldError 2!
    0 f_change 2!
    0 f_pErrorTerm 2!
    0 f_dErrorTerm 2!
    ." loop, left, right, error, change, pTerm, dTerm, leftSpeed, rightSpeed"
    cr
    250 ms 
    0 leftMezzLED pin!
    false markerToggle !

    begin robotRunning while
        readSensors
        checkMarkers
        sfTrigger @ if
            markerToggle @ not markerToggle !
            markerToggle @ rightMezzLED pin!
            false sfTrigger !
            robotState @ PRE_START_MARKER = if
                RUNNING robotState !
            else
                STOPPING robotState !
                loopCounter @ startCount !
            then
        then
        radiusTrigger @ if
            markerToggle @ not markerToggle !
            markerToggle @ rightMezzLED pin!
            false radiusTrigger !
        then

        robotState @ STOPPING = if
            loopCounter @ startCount @ - 50 < if     \ run on past the finih marker
                1 leftMezzLED pin!
            else
                HALTED robotState !
                0 leftMezzLED pin!
                false robotRunning !
            then

        rightSensorValue @ rightMin @ - 100 * rightMax @ rightMin @ - /
            rsensorCal !
        leftSensorValue @ leftMin @ - 100 * leftMax @ leftMin @ - /
            lsensorCal !

        \ detect loosing the line
        lsensorCal 25 > rsensorCal 25 > and if  \ on the line
            1 loopCounter @ +!
            f_lsensorCal 2@ f_rsensorCal 2@ d- f_error 2!   \ error = lsensorCal - rsensorCal
            f_error 2@ f_kp 2@ f* f_pErrorTerm 2!
            f_error 2@ f_oldError 2@ d- f_change 2!
            f_error f_oldError 2!
            f_change 2@ f_kdLoop 2@ f* f_dErrorTerm 2!
            f_speed 2@ f_pErrorTerm 2@ d- f_dErrorTerm 2@ d- f>s leftSpeed !
            f_speed 2@ f_pErrorTerm 2@ d+ f_dErrorTerm 2@ d+ f>s rightSpeed !
            displayLogging
            leftSpeed @ leftMotor
            rightSpeed @ rightMotor
            leftSpeed @ rightSpeed @ - 10 > if
                1 leftSensorLED pin!
                0 rightSensorLED pin!
            else
                rightSpeed @ leftSpeed @ - 10 > if
                    0 leftSensorLED pin!
                    1 rightSensorLED pin!
                else
                    0 leftSensorLED pin!
                    0 rightSensorLED pin!
            then
        else \ off the line
            false robotRunning !
        then
        leftButton pin@ 0 = if    \ left button stops the run and goes back to fast blinking
            false robotRunning !
        then
        loopPeriod ms
    repeat
    HALTED robotState !
    ." Robot halted"
    cr
    stopMotors            \ stop immediately
    1000 ms
;

: main-loop ( -- )
    init-GPIO
    init-state
    init-calibration
    initialiseMarkerFlags
    0 onBoardLED.value  \ turn off the LED

    false robotCalibrated !
    begin
        false robotRunning !
        stopMotors

        do_calibrate
        do_run
    again
;
