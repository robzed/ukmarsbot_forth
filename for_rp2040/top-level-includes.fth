\ Top-level includes and tests
\ Copyright (c) 2023 Rob Probin
\ MIT license, see LICENSE file
\
\ For use with zeptocom.js

\ compile-to-flash
#include programmer_misc.fth
#include sounds.fth
#include ABC_decoder.fth
\ ABC-decoder import
\ ABC_test
#include basic_io.fth
#include irq_info.fth
#include float_compatibility.fth
#include config.fth
#include WiFiNINA_gpio.fth
\ compile-to-ram
#include encoders.fth
#include robot-tick.fth
#include main-rp2040.fth
bip
unused
debugprompt



\ task-free


\ 
\ Test stuff not normally ran
\


#include main-rp2040.fth

WiFiNINA import
enable_NINA 
.s cr 
getFwVersion .s cr type cr
4 analogRead . 
5 analogRead .
6 analogRead . 
7 analogRead .

NinaPin_LEDR PinModeINPUT
NinaPin_LEDR digitalRead .
NinaPin_LEDR pinModeOUTPUT 
NinaPin_LEDR 1 digitalWrite 
NinaPin_LEDR digitalRead . 0 
NinaPin_LEDR 0 digitalWrite 
NinaPin_LEDR 1 digitalWrite 

NinaPin_LEDG pinModeOUTPUT
NinaPin_LEDG 1 digitalWrite
NinaPin_LEDG 0 digitalWrite

NinaPin_LEDB pinModeOUTPUT
NinaPin_LEDB 1 digitalWrite
NinaPin_LEDB 0 digitalWrite

: -r NinaPin_LEDR 0 digitalWrite ;
: +r NinaPin_LEDR 1 digitalWrite ;
: -g NinaPin_LEDG 0 digitalWrite ;
: +g NinaPin_LEDG 1 digitalWrite ;
: -b NinaPin_LEDB 0 digitalWrite ;
: +b NinaPin_LEDB 1 digitalWrite ;
i
NinaPin_LEDG 128 analogWrite



#include misc.fth


