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


\ Arduino Nano RP2040 Connect pins
\ Analog Pins 
  { p26,        NULL },    // A0
  { p27,        NULL },    // A1
  { p28,        NULL },    // A2
  { p29,        NULL },    // A3
};

\ Key:
\ RP2040 Pin, Arduino Pin - ukmarsbot Function when it's a Arduino Nano RP2040 Connect

\ digital pins
\ D0 - D7

  \ p1  D0 - serial txd (Forth)
  \ p0  D1 - serial rxd (Forth)
  \ p25 D2 - Left Clk A
  \ p15 D3 - Right Clk A
  \ p16 D4 - Left B
  \ p17 D5 - Right B
  \ p18 D6 - User IO (used for clk because of duplicate PWM channel P21 and P5)
  \ p19 D7 - Left Dir

\ D8 - D13

  \ p20 D8 - Right Dir
  \ p21 D9 - Left PWM
  \ p5  D10 - Right PWM
  \ p7  D11 / SPITX - Emitter A
  \ p4  D12 / SPIRX - Emitter B
  \ p6  D13 / SPICLK / LEDB - Buzzer

\ Analog as digital
\ A4 to A7 are controlled by Nina module and exposed via different APIs

  \ p26 A0 -> D14 - Sensor 0
  \ p27 A1 -> D15 - Sensor 1
  \ p28 A2 -> D16 - Sensor 2 
  \ p29 A3 -> D17 - Sensor 3

\ Nina ADC
  \ A4 / A5 - don't use, use for IMU
  \ A6 - Switches
  \ A7 - Battery 


\ I2C

  \ p12  A4 / SDA  -> D18  - Connected to IMU and Crypto
  \ p13  A5 / SCL  -> D19  - Connected to IMU and Crypto

\ Internal pins - D20 - D23

  \ p2   GPIO0    - used for Nina mode/IRQ
  \ p24  IMU IRQ
  \ p22  PDM DATA IN    - digital MEMS Microphone
  \ p23  PDM CLOCK      - digital MEMS Microphone

\ Internal pins Nina - D24 - D29

  \ p3   RESET_NINA
  \ p8   SPI1_CIPO / UART1_TX
  \ p9   SPI1_CS / UART1_RX
  \ p10  SPI1_ACK / UART1_CTS
  \ p11  SPI1_COPI / UART1_RTS
  \ p14  SPI1_SCK

