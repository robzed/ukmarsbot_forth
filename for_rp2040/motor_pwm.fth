\ ukmarsbot_forth
\ (c) 2022-2023 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: Robot Motor PWM for RP2040 on Zeptoforth

pin import
pwm import

255 constant MOTOR_MAX_PWM

#19 constant MOTOR_LEFT_DIR_PIN
#20 constant MOTOR_RIGHT_DIR_PIN
#18 constant MOTOR_LEFT_PWM_PIN  \ replacement for 21 because of PWM channels
#5  constant MOTOR_RIGHT_PWM_PIN
 1  constant MOTOR_LEFT_PWM_SLICE    \ 1A
: motor_left_pwm_compare! [inlined] pwm-counter-compare-a! ;
 2  constant MOTOR_RIGHT_PWM_SLICE    \ 2B
: motor_right_pwm_compare! [inlined] pwm-counter-compare-b! ;

: left_motor_pwm! ( n -- )
    MOTOR_MAX_PWM fnegate max MOTOR_MAX_PWM min
    MOTOR_LEFT_POLARITY *
    dup 0< MOTOR_LEFT_DIR_PIN pin!
    abs MOTOR_LEFT_PWM_SLICE motor_left_pwm_compare!
; 

: right_motor_pwm! ( n -- )
    MOTOR_MAX_PWM fnegate max MOTOR_MAX_PWM min
    MOTOR_RIGHT_POLARITY *
    dup 0< MOTOR_RIGHT_DIR_PIN pin!
    abs MOTOR_RIGHT_PWM_SLICE motor_right_pwm_compare!
;

: disable_motor_pwm ( -- )
    MOTOR_RIGHT_PWM_PIN input-pin
    MOTOR_RIGHT_PWM_SLICE bit disable-pwm

    MOTOR_LEFT_PWM_PIN input-pin
    MOTOR_LEFT_PWM_SLICE bit disable-pwm
;


: start_motor_pwm ( -- )

  \ disable before setup
  MOTOR_RIGHT_PWM_SLICE bit disable-pwm
  MOTOR_LEFT_PWM_SLICE bit disable-pwm

  \ Here we set our PWM slice to be free-running, rather than gated or a counter
  MOTOR_RIGHT_PWM_SLICE free-running-pwm
  MOTOR_LEFT_PWM_SLICE free-running-pwm

  \ Here we set phase correction off
  false MOTOR_RIGHT_PWM_SLICE pwm-phase-correct!
  false MOTOR_LEFT_PWM_SLICE pwm-phase-correct!

  \ Freq-PWM = Fsys / period
  \ period = (TOP+1) * (CSR_PH_CORRECT+1) + (DIV_INT + DIV_FRAC/16)
  \ e.g. 125 MHz / 16.0 = 7.8125 MHz rate base rate
  \ divider is 8 bit integer part, 4 bit fractional part
  \ Since phase correct is false/0, we only need to worry about TOP and Divider

  \ As the system clock is 125 MHz, this gives us a clock of 125000000/(15*(254+1)) = ~32 kHz
  \ You can calculate the actual clock with print-actual_frequency (out of sounds.fth)
  \ You could theoretically use calculate_closest_dividers (out of sounds.fth) but
  \ this uses a different top count, which we don't want here.
  0 15 MOTOR_RIGHT_PWM_SLICE pwm-clock-div!
  0 15 MOTOR_LEFT_PWM_SLICE  pwm-clock-div!

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
  254 MOTOR_RIGHT_PWM_SLICE pwm-top!
  254 MOTOR_LEFT_PWM_SLICE pwm-top!

  \ set current PWM value
  0 MOTOR_RIGHT_PWM_SLICE motor_right_pwm_compare!
  0 MOTOR_LEFT_PWM_SLICE motor_left_pwm_compare!

  \ make sure counter is zero
  0 MOTOR_RIGHT_PWM_SLICE pwm-counter!
  0 MOTOR_LEFT_PWM_SLICE pwm-counter!

  MOTOR_LEFT_DIR_PIN  output-pin
  MOTOR_RIGHT_DIR_PIN output-pin
  false MOTOR_LEFT_DIR_PIN  pin!
  false MOTOR_RIGHT_DIR_PIN pin!

  MOTOR_LEFT_PWM_PIN  pwm-pin
  MOTOR_RIGHT_PWM_PIN pwm-pin
  0 left_motor_pwm!
  0 right_motor_pwm!

  MOTOR_LEFT_PWM_SLICE bit enable-pwm
  MOTOR_RIGHT_PWM_SLICE bit enable-pwm
;



