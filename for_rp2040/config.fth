\ ukmarsbot_forth
\ (c) 2022-2023 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: Robot configuration

\ Based on  ukmars mazerunner core

\ -config
\ marker -config

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
0,0025 fconstant ROTATION_BIAS

\ these are in micrometers = µm
32,0 fconstant WHEEL_DIA    \ mm, adjust on test
12,0 fconstant ENCODER_PULSES \ per motor rev
19,540 fconstant GEAR_RATIO
37,0 fconstant MOUSE_RADIUS \ mm ... in reality this might be smaller or larger because of the contact patch between the wheels, so adjust on test.


\ ---------------------------------------------------

500,0 fconstant LOOP_FREQ

\ --------------------------------------------------------------------------------------

\ General Calculated values from Constants
\ ========================================
: ?swap if swap then ; 

3,14159 fconstant PI
WHEEL_DIA PI f* fconstant WHEEL_CIRCUM  \ mm
ENCODER_PULSES GEAR_RATIO f* fconstant PULSES/REV

\ MM_PER_COUNT_LEFT = (1 - ROTATION_BIAS) * PI * WHEEL_DIAMETER / (ENCODER_PULSES * GEAR_RATIO);
\ MM_PER_COUNT_RIGHT = (1 + ROTATION_BIAS) * PI * WHEEL_DIAMETER / (ENCODER_PULSES * GEAR_RATIO);

\ this the basic mm per pulse value
WHEEL_CIRCUM PULSES/REV f/ fconstant BASIC_mm/count

\ Finally assign the mm/COUNT for each side.
\ NOTICE: 2/ gives us an asymetric result, which allows us to leverage the bottom bit
\ usually this is about 428
1,0 ROTATION_BIAS f- BASIC_mm/count f* fconstant mm/COUNT_LEFT
1,0 ROTATION_BIAS f+ BASIC_mm/count f* fconstant mm/COUNT_RIGHT

\ ---------------------
\ DEG_PER_MM_DIFFERENCE = (180.0 / (2 * MOUSE_RADIUS * PI));

180,0 2,0 f/ WHEEL_CIRCUM f/ fconstant DEG/mm_DIFFERENCE

\ mm/COUNT_LEFT . 
\ mm/COUNT_RIGHT .
\ DEG/mm_DIFFERENCE . 


