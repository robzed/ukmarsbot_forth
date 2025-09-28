\ Orange DL2 LED by Rob Probin, August 2023.
\ USE WITH: Zeptoforth RP2040 zeptoforth_full-1.x.x.uf2
\ MIT License
\
\ NOTE: On my Arduino Nano RP2040 Connect board a passive buzzer is also 
\ connected to pin 6, so the LED will not be used

pin import 

6 constant ORANGE_LED
ORANGE_LED output-pin  
: orled1 true ORANGE_LED pin! ; 
: orled0 false ORANGE_LED pin! ; 
: orledc orled0 1 ms orled1 1 ms ; 
: orledloop 100 0 do orledc loop ; 

