\ ukmarsbot_forth
\ (c) 2022 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: Deals with the encoders

\ Based on  ukmars mazerunner core

-encoders
marker -encoders

\ Constants
\ =========

\ These allow you to select the forward count direction based on wiring, and orientation
\ encoder polarity is either 1 or -1 and is used to account for reversal of the encoder phases
-1 constant ENC_LEFT_POL
 1 constant END_RIGHT_POL

\ The robot is likely to have wheels of different diameters and that must be
\ compensated for if the robot is to reliably drive in a straight line
0.0025 constant ROTATION_BIAS \ Negative makes robot curve to left

32.0 constant WHEEL_DIA
12.0 constant ENCODER_PULSES
19.54 constant GEAR_RATIO
37.0 constant MOUSE_RADIUS

3.14159 constant PI
32 constant WHEEL_DIA
PI WHEEL_DIA * constant WHEEL_CIR


fix these! --------------------------------------------------<<<<<<<<<<<<----------------
1 constant MM_PER_COUNT_RIGHT
1 constant MM_PER_COUNT_LEFT

\ const float MM_PER_COUNT_LEFT = (1 - ROTATION_BIAS) * PI * WHEEL_DIAMETER / (ENCODER_PULSES * GEAR_RATIO);
\ const float MM_PER_COUNT_RIGHT = (1 + ROTATION_BIAS) * PI * WHEEL_DIAMETER / (ENCODER_PULSES * GEAR_RATIO);
\ const float DEG_PER_MM_DIFFERENCE = (180.0 / (2 * MOUSE_RADIUS * PI));

\ Variables
\ =========

\ None of the variables in this file should be directly available to the rest
\ of the code without a guard to ensure atomic access. 

\ 
variable my_distance
variable my_angle

\ the change in distance or angle in the last tick.
variable fwd_change;
variable rot_change;

\ internal use only to track encoder input edges
variable left_count
variable right_count


\ define the pins
\ ===============

PORTD 2 defPIN: ENC_LEFT_CLK
PORTD 3 defPIN: ENC_RIGHT_CLK
PORTD 4 defPIN: ENC_LEFT_B
PORTD 5 defPIN: ENC_RIGHT_B


\ Interrupt Service routines
\ ==========================

\ The ISR will respond to the XOR-ed pulse train from the encoder - i.e. 
\ both rising and falling interrupts

\ These are called on quite a high freqency for the ATmega328, so we 
\ need to be careful we only do the minimum possible. The calculation
\ work is done by a slower interrupt - like a 2ms timer interrupt.

\ left input change - interrupt service routine
variable l_oldA
variable l_oldB
: left_isr
    ENC_LEFT_B pin@
    ENC_LEFT_CLK pin@ over xor \ fix the A-xor-B input to A only.
    2dup
    \ we need to check the ENCODER_POLARITY * ((oldA ^ newB) - (newA ^ oldB));
    swap l_oldA @ xor ( newB newA newB newA -- newB newA newA newB^oldA )
    swap l_oldB @ xor (  -- newB newA newB^oldA newA^oldB )
    - ENC_LEFT_POL * ( -- newB newA delta )
    left_count +!   \ add delta onto counter

    \ store for next interrupt
    l_oldA !
    l_oldB !
;i

\ right input change - interrupt service routine
variable r_oldA
variable r_oldB
: right_isr
    ENC_RIGHT_B pin@
    ENC_RIGHT_CLK pin@ over xor \ fix the A-xor-B input to A only.
    2dup
    \ we need to check the ENCODER_POLARITY * ((oldA ^ newB) - (newA ^ oldB));
    swap r_oldA @ xor ( newB newA newB newA -- newB newA newA newB^oldA )
    swap r_oldB @ xor (  -- newB newA newB^oldA newA^oldB )
    - ENC_RIGHT_POL * ( -- newB newA delta )
    right_count +!   \ add delta onto counter

    \ store for next interrupt
    r_oldA !
    r_oldB !
;i


\ General Words
\ =============

: enc_reset
    \ atomic block
    di
    0 left_count !
    0 right_count !
    0 my_distance !
    0 my_angle !
    ei
;

: enc_setup
    0 l_oldA !
    0 l_oldB !
    0 r_oldA !
    0 r_oldB !
    ENC_LEFT_CLK input
    ENC_LEFT_B input
    ENC_RIGHT_CLK input
    ENC_RIGHT_B input
    enc_reset

    \ attachInterrupt(digitalPinToInterrupt(ENCODER_LEFT_CLK), callback_left, CHANGE);
    \ attachInterrupt(digitalPinToInterrupt(ENCODER_RIGHT_CLK), callback_right, CHANGE);
    di
        %00000101 EICRA mset \ set interupt triggers (rising or falling edges)
        %00000011 EIMSK mset \ Enable Int0 & Int1
        ['] left_isr $0002 int! \ Int0
        ['] right_isr $0003 int! \ Int1
    ei
;

\ this update function should be called from the periodic timer interrupt
\ The rate should be LOOP_FREQUENCY.
\ 
: enc_update
    right_count left_count
    \ Make sure values don't change while being read. Be quick.
    di
        @ swap @
        0 left_count !
        0 right_count !
    ei
    ( left_count right_count )

    \ calculate the change in millimeters
    MM_PER_COUNT_RIGHT *
    swap
    MM_PER_COUNT_LEFT *
    ( right left -- )

    2dup
    + 2/ fwd_change !
    - DEG_PER_MM_DIFFERENCE * rot_change !

    \ update cumulatives figures
    fwd_change @ my_distance +!
    rot_change @ my_angle +!
;

\ these access the variables in a safe manner
: distance ( -- distance )
    my_distance di @ ei
;

: speed ( -- speed )
    my_speed di @ ei
    LOOP_FREQUENCY *
;

: omega ( -- omega )
    rot_change di @ ei
    LOOP_FREQUENCY *
;

: fwd_change@  ( -- distance )
    fwd_change di @ ei
;

: rot_change@ ( -- distance )
    rot_change di @ ei
;

: angle ( -- angle )
    my_angle di @ ei
;

