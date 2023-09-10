\ ukmarsbot_forth
\ (c) 2023 Rob Probin 
\ MIT License, see LICENSE file
\ 

\ uses sounds.fth
: 1piezo 4100,0 tone_on ; \ Piezo resonant frequency
: 0piezo tone_off ; 
: short_beep 1piezo 20 ms 0piezo ;
: bip 1piezo 40 ms 0piezo ;
: beep 1piezo 100 ms 0piezo ;
: double_beep 1piezo 70 ms 0piezo 100 ms 1piezo 70 ms 0piezo ;

: ttone ( freq ms -- ) swap s>f tone_on ms tone_off ;
\
\ from Tachyon.fth
\
: 3RD     2 PICK ;
: BEEPS 0 DO beep 50 ms LOOP ;
: bips 0 DO bip 500 ms loop ;
: WARBLE ( hz1 hz2 ms -- )    3 0 DO 3RD OVER ttone 2DUP ttone LOOP DROP 2DROP ;
: SIREN			400 550 400 WARBLE ;
: ZAP 3000 100 DO I 15 I 300 / - ttone 200 +LOOP ;
: ZAPS ( cnt -- ) 0 DO ZAP 50 ms LOOP ;
: SAUCER 10 0 DO 600 50 ttone 580 50 ttone LOOP ;
: invaders SAUCER ZAP SAUCER 3 ZAPS SIREN ;

