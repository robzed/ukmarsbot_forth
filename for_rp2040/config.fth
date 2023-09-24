\ ukmarsbot_forth
\ (c) 2022-2023 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: Robot configuration

\ Based on  ukmars mazerunner core


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
\ General Calculated values to 'Constants' (actually reconfigurable)
\ Includes formulas for 'constants'
\ 
\ Use of constants before value is to get around the Zeptforth 
\ requirement to reboot before using values - since values are 
\ calculated from values, you can't use them to define further values.

\ These allow you to select the forward count direction based on wiring, and orientation
\ encoder polarity is either 1 or -1 and is used to account for reversal of the encoder phases
-1 constant ENC_LEFT_POL
 1 constant ENC_RIGHT_POL

\ Ihe motors may be wired with different polarity and that is defined here so that
\ setting a positive voltage always moves the robot forwards
1 constant MOTOR_LEFT_POLARITY
-1 constant MOTOR_RIGHT_POLARITY

\ The robot is likely to have wheels of different diameters and that must be
\ compensated for if the robot is to reliably drive in a straight line.
\ Negative makes robot curve to left
0,0025 fconstant ROTATION_BIAS_DEFAULT

\ these are in millimeters = mm
32,0 fconstant   WHEEL_DIA_DEFAULT      \ mm, adjust on test
12,0 fconstant   ENCODER_PULSES_DEFAULT \ per motor rev
19,540 fconstant GEAR_RATIO_DEFAULT
37,0 fconstant   MOUSE_RADIUS_DEFAULT   \ mm ... in reality this might be smaller or larger because of the contact patch between the wheels, so adjust on test.

500,0 fconstant LOOP_FREQ
1,0 LOOP_FREQ f/ fconstant LOOP_INTERVAL

\ not required for zeptoforth
\ 3,1415926499 fconstant PI

\
\ Define the actual values we use - these allow adjustment at runtime.
\ Call `calc-config` after adjusting
\
ROTATION_BIAS_DEFAULT  fvalue ROTATION_BIAS
WHEEL_DIA_DEFAULT      fvalue WHEEL_DIA
ENCODER_PULSES_DEFAULT fvalue ENCODER_PULSES
GEAR_RATIO_DEFAULT     fvalue GEAR_RATIO
MOUSE_RADIUS_DEFAULT   fvalue MOUSE_RADIUS

\ ---------------------------------------------------
\ General Formulas

: diameter>circum ( f.diameter -- f ) PI f* ; 
: calc_mm/count_left ( f.mm/count f.bias -- f ) 1,0 fswap f- f* ;
: calc_mm/count_right ( f.mm/count f.bias -- f ) 1,0 f+ f* ;

\ DEG_PER_MM_DIFFERENCE = (180.0 / (2 * MOUSE_RADIUS * PI));
: calc_deg/mm_diff ( f.mouse_radius -- f ) 180,0 fswap 2,0 f* pi f* f/ ; 

\ ---------------------------------------------------
\ Main parameters as values


\ MM_PER_COUNT_LEFT = (1 - ROTATION_BIAS) * PI * WHEEL_DIAMETER / (ENCODER_PULSES * GEAR_RATIO)
\ MM_PER_COUNT_RIGHT = (1 + ROTATION_BIAS) * PI * WHEEL_DIAMETER / (ENCODER_PULSES * GEAR_RATIO)
\ Calculate the mm/COUNT for each side.
\ NOTICE: 2/ gives us an asymetric result, which allows us to leverage the bottom bit
\ usually this is about 428
WHEEL_DIA_DEFAULT diameter>circum            \ wheel circumference
ENCODER_PULSES_DEFAULT GEAR_RATIO_DEFAULT f* \ pulses per wheel revolution (as opposed to pulses per motor revolution)
( wheel circumference ) ( pulses / rev ) f/  \ basic mm/count without left/right adjustment
fdup ( BASIC_mm/count ) ROTATION_BIAS_DEFAULT calc_mm/count_left  fvalue mm/COUNT_LEFT
     ( BASIC_mm/count ) ROTATION_BIAS_DEFAULT calc_mm/count_right fvalue mm/COUNT_RIGHT

MOUSE_RADIUS_DEFAULT calc_deg/mm_diff    fvalue DEG/mm_DIFFERENCE


\
\ recalculate calculated values
\
: calc-config
    \ 
    \ notice the calculations should be the same as above
    WHEEL_DIA diameter>circum            \ wheel circumference
    ENCODER_PULSES GEAR_RATIO_DEFAULT f* \ pulses per wheel revolution (as opposed to pulses per motor revolution)
    ( wheel circumference ) ( pulses / rev ) f/  \ basic mm/count without left/right adjustment
    fdup ( BASIC_mm/count ) ROTATION_BIAS calc_mm/count_left  to mm/COUNT_LEFT
         ( BASIC_mm/count ) ROTATION_BIAS calc_mm/count_right to mm/COUNT_RIGHT

    \ DEG_PER_MM_DIFFERENCE = (180.0 / (2 * MOUSE_RADIUS * PI));
    MOUSE_RADIUS calc_deg/mm_diff to DEG/mm_DIFFERENCE
;

: show-config
    ." ROTATION_BIAS " ROTATION_BIAS f. cr
    ." WHEEL_DIA " WHEEL_DIA f. cr
    ." ENCODER_PULSES " ENCODER_PULSES f. cr
    ." GEAR_RATIO " GEAR_RATIO f. cr
    ." MOUSE_RADIUS " MOUSE_RADIUS f. cr

    ." mm/COUNT_LEFT " mm/COUNT_LEFT f. cr
    ." mm/COUNT_RIGHT " mm/COUNT_RIGHT f. cr
    ." DEG/mm_DIFFERENCE " DEG/mm_DIFFERENCE f. cr
;

