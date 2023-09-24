\ Top-level includes and tests
\ Copyright (c) 2023 Rob Probin
\ MIT license, see LICENSE file
\
\ For use with zeptocom.js

compile-to-flash
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
#include encoders.fth
#include robot-adc.fth
#include motor_pwm.fth
compile-to-ram

#include robot-tick.fth
#include main-rp2040.fth
bip
unused
debugprompt
main


\ ========================================
\ test items


robot-distance f. robot-angle f.

\ testing
enable_emitters
show-sensors



start_motor_pwm
0 right_motor_pwm!
0 left_motor_pwm!


