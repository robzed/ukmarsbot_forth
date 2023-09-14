\ ukmarsbot_forth
\ (c) 2022-2023 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: Robot configuration

\ Based on  ukmars mazerunner core

\ -config
\ marker -config

\ These are values rather than constants so they can be adjusted these from the Forth console.
\ For Zeptoforth see https://github.com/tabemann/zeptoforth/wiki/VALUEs-and-Lexically-Scoped-Local-Variables

decimal 

\ The constants here aim to have Robot natural units - seconds, millimeters, etc. for ease of use.
\ 
\ For Zeptoforth on the RP2040 we use S31.32 fixed-point math using double cells.
\ For Flashforth on the PIC33F we use Floating-point single-precision math.
\ If we wanted to use is a 16-bit integer Forth (e.g. FlashForth on the ATMega328P Arduino Nano)
\   you could to use a double cell to get 32 bit fixed point - but the range isn't great
\   and you end up messing with the scales of constants which is a complete range.
\ 
\ The C++ UKMARS mazerunner and Peter's mazerunner-core used single precision floating point.
\ We could use the RP2040 single or double precision libraries into Zeptoforth (as used in BootROM, 
\ a licensed version of the FP library) perhaps with changes to avoid using r7 (the DSP that's assumed 
\ by all Zeptoforth interrupt routines).

\ Robot Specific Constants
\ ========================

\ These allow you to select the forward count direction based on wiring, and orientation
\ encoder polarity is either 1 or -1 and is used to account for reversal of the encoder phases
-1 constant ENC_LEFT_POL
 1 constant ENC_RIGHT_POL

\ The robot is likely to have wheels of different diameters and that must be
\ compensated for if the robot is to reliably drive in a straight line.
\ Negative makes robot curve to left
0,0025 fvalue ROTATION_BIAS

\ these are in millimeters = mm
32,0 fvalue WHEEL_DIA    \ mm, adjust on test
12,0 fvalue ENCODER_PULSES \ per motor rev
19,540 fvalue GEAR_RATIO
37,0 fvalue MOUSE_RADIUS \ mm ... in reality this might be smaller or larger because of the contact patch between the wheels, so adjust on test.


\ ---------------------------------------------------
\ General Constants

500,0 fconstant LOOP_FREQ
\ not required for zeptoforth
\ 3,1415926499 fconstant PI

\ General Calculated values to 'Constants' (actually reconfigurable)
\ Includes formulas for 'constants'
\ =================================================================

: calc_wheel_circum ( -- f ) WHEEL_DIA PI f* ; 
calc_wheel_circum   fvalue WHEEL_CIRCUM  \ mm

: calc_pulses/rev ( -- f ) ENCODER_PULSES GEAR_RATIO f* ;
calc_pulses/rev     fvalue PULSES/REV

\ this the basic mm per pulse value
: calc_mm/count ( -- f ) WHEEL_CIRCUM PULSES/REV f/ ;
calc_mm/count       fvalue BASIC_mm/count

\ MM_PER_COUNT_LEFT = (1 - ROTATION_BIAS) * PI * WHEEL_DIAMETER / (ENCODER_PULSES * GEAR_RATIO);
\ MM_PER_COUNT_RIGHT = (1 + ROTATION_BIAS) * PI * WHEEL_DIAMETER / (ENCODER_PULSES * GEAR_RATIO);

\ Finally the mm/COUNT for each side.
\ NOTICE: 2/ gives us an asymetric result, which allows us to leverage the bottom bit
\ usually this is about 428
: calc_mm/count_left ( -- f ) 1,0 ROTATION_BIAS f- BASIC_mm/count f* ;
calc_mm/count_left  fvalue mm/COUNT_LEFT

: calc_mm/count_right ( -- f ) 1,0 ROTATION_BIAS f+ BASIC_mm/count f* ;
calc_mm/count_right fvalue mm/COUNT_RIGHT

\ DEG_PER_MM_DIFFERENCE = (180.0 / (2 * MOUSE_RADIUS * PI));

: calc_deg/mm_diff ( -- f ) 180,0 2,0 f/ WHEEL_CIRCUM f/ ; 
calc_deg/mm_diff    fvalue DEG/mm_DIFFERENCE

\
\ recalculate calculated values
\
: calc-config
    \ 
    \ notice the calculations should be the same as above
    \ 
    calc_wheel_circum   to WHEEL_CIRCUM  \ mm
    calc_pulses/rev     to PULSES/REV
    calc_mm/count       to BASIC_mm/count
    calc_mm/count_left  to mm/COUNT_LEFT
    calc_mm/count_right to mm/COUNT_RIGHT
    calc_deg/mm_diff    to DEG/mm_DIFFERENCE
;

: show-config
    ." mm/COUNT_LEFT " mm/COUNT_LEFT f. cr
    ." mm/COUNT_RIGHT " mm/COUNT_RIGHT f. cr
    ." DEG/mm_DIFFERENCE " DEG/mm_DIFFERENCE f. cr
;

