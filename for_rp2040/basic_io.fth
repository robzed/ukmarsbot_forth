\ ukmarsbot_forth
\ (c) 2023 Rob Probin 
\ MIT License, see LICENSE file
\ 

pin import

6 constant buzzer

: beep 1 buzzer pin! ;
: 0beep 0 buzzer pin! ; 
: short_beep beep 20 ms 0beep ;
: long_beep beep 100 ms 0beep ;
: double_beep beep 70 ms 0beep 100 ms beep 70 ms 0beep ;

: setup-basic-IO
    buzzer output-pin
;


