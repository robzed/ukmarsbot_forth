\  by Rob Probin, August 2023.
\ Includes:
\  Orange DL2 LED on Arduino Nano RP2040 Connect board (overlaps with passive buzzer)
\  P18 Red Right Sensor Board LED (also used for Left PWM)
\  P7 Yellow Left Sensor Board LED (not used for anything else)
\
\ USE WITH: Zeptoforth RP2040 zeptoforth_full-1.x.x.uf2
\ MIT License

pin import 

\ Duplicated use of this pin for passive buzzer - so don't use for LED
6 constant ORANGE_LED
: orled1 true ORANGE_LED pin! ; 
: orled0 false ORANGE_LED pin! ; 
: orledc orled0 1 ms orled1 1 ms ; 
: orledloop 100 0 do orledc loop ; 

\ we could use this Yellow LED
7 constant SENSOR_LEFT_LED
: yled1 true SENSOR_LEFT_LED pin! ; 
: yled0 false SENSOR_LEFT_LED pin! ; 

\ Duplicated use of this pin for Left PWM - so don't use for LED
18 constant SENSOR_RIGHT_LED
: srled1 true SENSOR_RIGHT_LED pin! ; 
: srled0 false SENSOR_RIGHT_LED pin! ; 


: unused_led_init
    SENSOR_LEFT_LED output-pin  
    SENSOR_RIGHT_LED output-pin  
    ORANGE_LED output-pin  
;

unused_led_init
