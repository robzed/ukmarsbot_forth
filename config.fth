\ ukmarsbot_forth
\ (c) 2022-2023 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: Robot configuration

\ Based on  ukmars mazerunner core

-config
marker -config

decimal 

\ NOTICE: Flashforth is a 16 bit forth, you need to use a double cell to get 32 bit (2constant)
\ We could have used some sort of floating point support, like the C/C++ version of UKMARS
\ but we decided to use integer maths to make installing FlashForth on the Nano simpler.

\ Robot Specific Constants
\ ========================

\ These allow you to select the forward count direction based on wiring, and orientation
\ encoder polarity is either 1 or -1 and is used to account for reversal of the encoder phases
-1 constant ENC_LEFT_POL
 1 constant END_RIGHT_POL

\ The robot is likely to have wheels of different diameters and that must be
\ compensated for if the robot is to reliably drive in a straight line.
\ Negative makes robot curve to left
3 constant ROTATION_BIAS

\ these are in micrometers = µm
32000 constant WHEEL_DIA    \ µm, adjust on test
12 constant ENCODER_PULSES \ per motor rev
19540 constant GEAR_RATIO   \ x1000
37000 constant MOUSE_RADIUS \ µm

\ NOTES ABOUT SCALING
\ If your wheel diameter exceeds 65.535 mm, then you need to alter the scaling below.
\ If your gear ratio exceeds 65.535:1 then you need to alter the scaling below.
\ For UK mars bot, the radius will never go beyond 65mm :-)

\ ---------------------------------------------------

500 constant LOOP_FREQ

\ --------------------------------------------------------------------------------------

\ General Calculated values from Constants
\ ========================================
\ Unsigned division. ( ud u1 -- ud.quot ) 32-bit/16-bit to 32-bit
: ud/ ud/mod rot drop ;
: ?swap if swap then ; 

\ 31416 constant PI        \ x10000 good enough for us
3142 constant PI        \ x1000 good enough for us
WHEEL_DIA PI um* 2constant WHEEL_CIRCUM \ nanometers
\ ENCODER_PULSES GEAR_RATIO um* 2constant PULSES/REV

\ MM_PER_COUNT_LEFT = (1 - ROTATION_BIAS) * PI * WHEEL_DIAMETER / (ENCODER_PULSES * GEAR_RATIO);
\ MM_PER_COUNT_RIGHT = (1 + ROTATION_BIAS) * PI * WHEEL_DIAMETER / (ENCODER_PULSES * GEAR_RATIO);

\ this the basic µm (micrometers) per pulse value
WHEEL_CIRCUM GEAR_RATIO ud/ ENCODER_PULSES ud/ drop dup

\ Finally assign the UM/COUNT for each side.
\ NOTICE: 2/ gives us an asymetric result, which allows us to leverage the bottom bit
\ usually this is about 428
ROTATION_BIAS negate 2/ + constant UM/COUNT_LEFT
ROTATION_BIAS 2/ + constant UM/COUNT_RIGHT

\ ---------------------
\ DEG_PER_MM_DIFFERENCE = (180.0 / (2 * MOUSE_RADIUS * PI));

\ first calculate half circumference in µm, typically around 116239 (116.239 mm)
\ divide by 10 to make it fit into u16  ( = 11625). So this is 10 times too big for um.
MOUSE_RADIUS PI um* 10000 ud/ drop

\ M_DIFF = Meter difference, deg/m is typically around 774 (1 deg = 0.774mm)
\ We compensate for the 10/ above by reducing one of the 1000's to 100.
90 1000 um* 100 ud* rot ud/ drop constant DEG/M_DIFF

\ UM/COUNT_LEFT . 
\ UM/COUNT_RIGHT .
\ DEG/M_DIFF . 


