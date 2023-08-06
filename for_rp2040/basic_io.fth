
pin import
6 output-pin

: beep 1 6 pin! ;
: 0beep 0 6 pin! ; 
: short_beep beep 20 ms 0beep ;
: long_beep beep 100 ms 0beep ;


