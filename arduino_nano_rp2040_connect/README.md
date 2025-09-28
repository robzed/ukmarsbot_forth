# ukmarsbot_forth

Basic control of the UKMARSBot in Forth for Arduino Nano RP2040 Connect 
with Zeptoforth for Wall Following and Maze Solving

# Environment

I'm currently running Zeptforth Welcome to zeptoforth, Built for rp2040_big, version 1.14.2.3. 

I also loaded Zeptoforth's ssd1306 onto the board - this is added onto with 'display.f'.




# Licence

This code is Licensed under the MIT license.

(c) 2022-2025 Rob Probin.


# GPIO Mapping for Arduino Nano RP2040 Connect on UKMARSBot

The Arduino Nano RP2040 Conect has set of GPIO that are mapped in this code as follows:

Key: RP2040 Pin, Arduino Pin - ukmarsbot Function when it's a Arduino Nano RP2040 Connect

## Digital pins

### D0 - D7

p1  D0 - serial txd (Forth)
p0  D1 - serial rxd (Forth)
p25 D2 - Left Clk A
p15 D3 - Right Clk A
p16 D4 - Left B
p17 D5 - Right B
p18 D6 - User IO - used for Left PWM because of duplicate PWM channel P21 and P5. (PWM1A)
p19 D7 - Left Dir

### D8 - D13

p20 D8 - Right Dir
p21 D9 - Left PWM (PWM2B) **NOT** Left PWM - leave as input! Use p18/D6 instead.
p5  D10 - Right PWM (PWM2B)
p7  D11 / SPITX - Emitter A (only used on 4 wall sensor board and mini wide, LED on other boards)
p4  D12 / SPIRX - Emitter B (used on all)
p6  D13 / SPICLK / LEDB - Buzzer (PWM3A)

## Analog as digital

### A4 to A7 are controlled by Nina module and exposed via different APIs

p26 A0 -> D14 - Sensor 0
p27 A1 -> D15 - Sensor 1
p28 A2 -> D16 - Sensor 2 
p29 A3 -> D17 - Sensor 3

### Nina ADC

A4 / A5 - don't use, use for IMU (also used on and the authenicator secure element IC)
A6 - Switches
A7 - Battery 

## I2C

p12  A4 / SDA  -> D18  - Connected to IMU and ECC608 Authenticator (Crypto chip) - and also ssd1306 128x64 OLED display
p13  A5 / SCL  -> D19  - Connected to IMU and ECC608 Authenticator (Crypto chip) - 


## Internal pins - D20 - D23

p2   GPIO0    - used for Nina mode/IRQ
p24  IMU IRQ
p22  PDM DATA IN    - digital MEMS Microphone
p23  PDM CLOCK      - digital MEMS Microphone

The digital MEMS microphone could be used to detect robot crashes, potentially.

## Internal pins Nina - D24 - D29

p3   RESET_NINA
p8   SPI1_CIPO / UART1_TX
p9   SPI1_CS / UART1_RX
p10  SPI1_ACK / UART1_CTS
p11  SPI1_COPI / UART1_RTS
p14  SPI1_SCK


## Nina Information

The Nina supplied connections

RGB LED - Common Anode, Connected to U-blox® Nina W102 GPIO

### Nina Interconnect

The RP2040 and the Nina are connected together with:
 * SPI
 * UART
 * I2C

 The A4/A5 pins are also I2C pins and are also connected to the IMU and ECC608
Authenticator. 

We could also use the I2C to connect an LCD display.

The NINA W102 has a WiFi and Bluetooth. 

## I2C

i2c-scanner import

12 13 0 scan-i2c

Appeared 3C 6A 
$3C constant SSD1306_I2C_ADDR

LSM6DSOXTR I2C addresses
 
    0x6A (HEX): This is the default I2C address, used when the SA0 pin is connected to ground (GND) or left floating. On many breakout boards, this connection is the default.
  0x6B (HEX): This address is used when the SA0 pin is connected to a high voltage (3.3V)

ATECC608A-MAHDA-T i2c address
7-bit address: 0x60
8-bit programmed address value: 0xC0

## LEDs

There are three LEDs on the Arduino Nano RP2040 Connect:

 * DL1 - Green Power On LED (always on, via SJ2)
 * DL2 - Orange LED connected to SPICLK~ / GPIO6. (Also connected to Buzzer on my robot.)
 * DL3 - RGB LED connected to the NINA 

## Sensor Header vs. LCD

0.96" OLED Display Module (128x64)

The LCD has, from left to right: Vcc, GND, SCL, SDA.
The left side of the UKMARSBot sensor connector has Vcc, GND, A5, A4.
From above, we know that A4 is SDA, and A5 is SCL.

So the two connections align. 

https://thepihut.com/products/0-96-oled-display-module-128x64?variant=42810024820931


# Features Considered

    - LCD - basic
    - LCD - menu
    - Buzzer on/off
    - Button input reading
    - Switch input reading
    - LED on/off - on nano board. The GPIO is used for a passive buzzer, so normallty doesn't turn on
    - LED on/off - sensor board left/right LEDs
    - RGB LED - colours
    - motors forward/back
    - speed sensors (encoders)
    - Run at constant speed 
    - Wall sensors - Basic raw analogue read
    - make music
    - Do calibration for wall sensors
    - Wall sensors - distances
    - Wall sensors - wall tracking
    - Wall sensors - map filling
    - LCD - draw map 
    - Follow left wall
    - Follow right wall
    - PWM buzzer?
    - Battery voltage reading
    - On-board Wi-Fi
    - On-board Bluetooth
    - HC05/HC06 wireless

