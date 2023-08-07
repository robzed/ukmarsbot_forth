\ Arduino Nano RP2040 Connect WifiNINA support
\
\ Copyright (c) 2023 Rob Probin
\
\ MIT License
\ 
\ Permission is hereby granted, free of charge, to any person obtaining a copy
\ of this software and associated documentation files (the "Software"), to deal
\ in the Software without restriction, including without limitation the rights
\ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
\ copies of the Software, and to permit persons to whom the Software is
\ furnished to do so, subject to the following conditions:
\ 
\ The above copyright notice and this permission notice shall be included in
\ all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
\ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
\ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
\ AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
\ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
\ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
\ SOFTWARE.

decimal 
begin-module WiFiNINA
    begin-module WiFiNINA-spi
    
    \ Cmd Struct Message
    \  _________________________________________________________________________________
    \ | START CMD | C/R  | CMD  |[TOT LEN]| N.PARAM | PARAM LEN | PARAM  | .. | END CMD |
    \ |___________|______|______|_________|_________|___________|________|____|_________|
    \ |   8 bit   | 1bit | 7bit |  8bit   |  8bit   |   8bit    | nbytes | .. |   8bit  |
    \ |___________|______|______|_________|_________|___________|________|____|_________|

    $E0 constant START_CMD
    $EE constant END_CMD
    $EF constant ERR_CMD

    \ 0 constant CMD_FLAG
    1 7 LSHIFT constant REPLY_FLAG
    \ $40 constant DATA_FLAG

    spi import
    pin import
    systick import

    \ pin defs for Nina on NanoRP2040 Connect
    \ https://github.com/arduino/ArduinoCore-mbed/blob/24138cc4b958d633ccb813d85fa1bab8a29f9693/variants/NANO_RP2040_CONNECT/variant.cpp
    9 constant NINA_CS
    10 constant NINA_READY
    3 constant NINA_RESET
    2 constant NINA_GPIO0   \ same as NINA_IRQ
    2 constant NINA_IRQ     \ same as NINA_QPIO0

    \ false value SPI_init_f

    : SPI_NINA_deselect ( -- )
        high NINA_CS pin!
    ;

    : time_start ( milliseconds-to-expire -- timeVal )
       10 * systick-counter +
    ;
    : time_expired ( timeVal -- )
        systick-counter <
    ;

    : SPI_NINA_ready ( -- ready? ) NINA_READY pin@ not ;

    : SPI_NINA_select ( -- )
        \ ." readyss1=" SPI_NINA_ready .
        low NINA_CS pin!
        \ ." readyss2=" SPI_NINA_ready .

        \ wait for 5ms in case Nina is not ready for transfer
        \ timeout will be module broken/missing
        \ wait for NINA ready
        5 time_start 
        begin dup time_expired SPI_NINA_ready not or until 
        \ dup time_expired ." expired=" .
        \ ." readyss3=" SPI_NINA_ready .
        drop
    ;

    : SPI_wait_for_NINA_ready ( -- )
        \ ." ready1=" SPI_NINA_ready .
        1000 time_start
        begin dup time_expired dup if ." WSS-T/O" then SPI_NINA_ready or until drop
        \ ." ready2=" SPI_NINA_ready .
    ;

    : SPI_setup ( -- )

        NINA_CS output-pin \ SPI NINA_select
        NINA_READY input-pin
        NINA_RESET output-pin
        NINA_GPIO0 output-pin

        high NINA_GPIO0 pin! 
        high NINA_CS pin!
        low NINA_RESET pin!    \ @TODO - is this correct polarity
        10 ms
        high NINA_RESET pin!
        750 ms

        low NINA_GPIO0 pin!
        NINA_IRQ input-pin      \ same as GPIO0

        1 8 spi-pin \ SPI1 RX
\        1 9 spi-pin \ SPI1 CSn
        1 14 spi-pin \ SPI1 SCK
        1 11 spi-pin \ SPI1 TX
        1 master-spi
        8000000 1 spi-baud!
        8 1 spi-data-size!
        \    1 ti-ss-spi
        \ true false 1 motorola-spi
        \ https://docs.arduino.cc/learn/communication/spi
        \ Mode      Clock Polarity (CPOL)   Clock Phase (CPHA)  Output Edge     Data Capture
        \ SPI_MODE0 0                       0                   Falling         Rising
        \ SPI_MODE1 0                       1                   Rising          Falling
        \ SPI_MODE2 1                       0                   Rising          Falling
        \ SPI_MODE3 1                       1                   Falling         Rising

        \ Zeptoforth: ( sph spo spi – )
        \ Set the protocol of an SPI peripheral to Motorola SPI, with SPO/CPOL set to spo and 
        \ SPH/CPHA set to sph. This must be done with the SPI peripheral disabled.
        false false 1 motorola-spi        
        \ The SPI settings for the Wifi NINA are:  8000000, MSBFIRST, SPI_MODE0

        1 enable-spi

        \ true to Spi_init_f
    ; 

    : SPI_wait_for_SS  ( -- )
        \ SPI_init_f 0= if
        \    SpiSetup 
        \ then
        SPI_wait_for_NINA_ready
        SPI_NINA_select
    ;

    : SPI_send ( byte -- )
        \ dup ." send(" hex . decimal ." ) "
        1 >spi 1 spi> drop 
        \ ." rx_got(" hex . decimal ." ) "
    ;

    : SPI_read_8 ( -- u8 )
        \ FF is dummy data
        $FF 1 >spi 1 spi>
        \ dup ." got(" hex . decimal ." ) "
    ; 

    : SPI_read_be16 ( -- u16 )
        SPI_read_8 8 lshift
        SPI_read_8 +
    ;

    : SPI_wait_SPI_char ( waitChar -- success )
        1000 time_start swap
        begin
            SPI_read_8 ( time waitChar newChar )
            2dup = if drop 2drop ( ." good " ) true exit then
            ERR_CMD = if 2drop ( ." Err " ) false exit then
            over time_expired
        until 2drop false
    ; 

    : SPI_get_response_cmd ( dest-addr params command -- number_returned  ) 
        \ hex .s decimal
        START_CMD SPI_wait_SPI_char not if ." Not start" drop 2drop 0 exit then

        REPLY_FLAG + SPI_read_8 <> if ." Wrong command" cr 2drop 0 exit then 

        \ check correct number of params
        SPI_read_8 = if
            \ now get the data
            SPI_read_8 tuck 0 ?do 
                \ Get Params data
                SPI_read_8 over c!
                1+ 
                loop
            drop
        else
                ." wrong params" cr
                drop 0 exit
        then

        END_CMD SPI_read_8 <> if ." No end?" then  \ ignored @TODO check?
    ;

    : SPI_send_cmd ( params command -- )
        START_CMD SPI_send
        SPI_send    \ top bit should be clear (REPLY_FLAG)
        \ no total length in this packet
        dup SPI_send \ #params
        0= if END_CMD SPI_send then
    ;

    : SPI_send_param ( lastParam? param -- )
        \ Send SPI paramLen
        2 SPI_send

        \ big-endian parameter
        dup 8 rshift SPI_send
        $ff and SPI_send

        if END_CMD SPI_send then
    ;
    : SPI_send_param16 ( param -- )
        \ Send SPI paramLen
        2 SPI_send

        \ big-endian parameter
        dup 8 rshift SPI_send
        $ff and SPI_send
    ;
    : SPI_send_param8 ( param -- )
        \ Send SPI paramLen
        1 SPI_send

        \ big-endian parameter
        SPI_send
    ;

    end-module> import


    : enable_NINA ( -- )
        SPI_setup
    ; 

    \ command codes
    $50 constant SET_PIN_MODE
    $51 constant SET_DIGITAL_WRITE
    $52 constant SET_ANALOG_WRITE
    $53 constant GET_DIGITAL_READ
    $54 constant GET_ANALOG_READ
    $37 constant GET_FW_VERSION_CMD

    27 constant NinaPin_LEDR
    25 constant NinaPin_LEDG
    26 constant NinaPin_LEDB
    34 constant NinaPin_A4
    39 constant NinaPin_A5
    36 constant NinaPin_A6
    35 constant NinaPin_A7

    : toAnalogPin ( pin -- ch )
        dup 4 = if drop 6 exit then \ ch 6 on ADC1
        dup 5 = if drop 3 exit then \ ch 3 on ADC1
        dup 6 = if drop 0 exit then \ ch 0 on ADC1
        dup 7 = if drop 7 exit then \ ch 7 on ADC1
        drop $FF
    ;

    : _send2 ( param param cmd -- )
        SPI_wait_for_SS
        2 swap SPI_send_cmd
        swap    \ pin mode other way around
        SPI_send_param8
        SPI_send_param8
        END_CMD SPI_send
        \ pad to multiple of 4
        SPI_read_8 drop

        SPI_NINA_deselect
    ;
 
    4 buffer: TempReturnBuf    
    : _rcv1 ( cmd -- )
        \ Wait the reply 
        SPI_wait_for_NINA_ready
        2 ms
        SPI_NINA_select
        2 ms

        TempReturnBuf swap 1 swap SPI_get_response_cmd
        SPI_NINA_deselect
    ;

    : pinMode ( pin mode -- )
        swap    \ pin mode other way around
        SET_PIN_MODE _send2
        SET_PIN_MODE _rcv1 drop
    ;

    : PinModeINPUT ( pin -- ) 0 PinMode ; 
    : PinModeOUTPUT ( pin -- ) 1 PinMode ; 
    : PinModeINPUT_PULLUP ( pin -- ) 2 PinMode ; 
    : PinModeINPUT_PULLDOWN ( pin -- ) 3 PinMode ; 
    : PinModeOUTPUT_OPENDRAIN ( pin -- ) 4 PinMode ; 
    
    : digitalRead ( pin -- state )
        \ @TODO
    ;

    : digitalWrite ( pin state -- )
        \ inverted state 0 or 1 to NINA
        0= if 1 else 0 then
        SET_DIGITAL_WRITE _send2
        SET_DIGITAL_WRITE _rcv1 drop
    ;

    : analogRead ( pin -- value )
        toAnalogPin
        \ @TODO
    ;


    : analogWrite ( pin value -- )
        \ @TODO
        2drop
    ;

    \ firmware version string length
    6 constant WL_FW_VER_LENGTH

    WL_FW_VER_LENGTH buffer: FwVersionCStr

    : getFwVersion ( -- versionstr vlen )
        SPI_wait_for_SS
        0 GET_FW_VERSION_CMD SPI_send_cmd

        SPI_NINA_deselect


        \ Wait the reply elaboration
        SPI_wait_for_NINA_ready
        2 ms
        SPI_NINA_select
        \ ." Wait reply" CR
        2 ms
        FwVersionCStr dup 1 GET_FW_VERSION_CMD SPI_get_response_cmd
        SPI_NINA_deselect
    ;

end-module


\ #test items
\ 
\ WiFiNINA import 
\ enable_NINA
\ getFwVersion .s cr type cr
\
\ NinaPin_LEDB 1 pinMode .s
\ NinaPin_LEDB 1 digitalWrite
\ NinaPin_LEDB 0 digitalWrite
\ 
\ NinaPin_LEDG pinModeOUTPUT
\ NinaPin_LEDG 1 digitalWrite
\ NinaPin_LEDG 0 digitalWrite
\ 
\ NinaPin_LEDR pinModeOUTPUT
\ NinaPin_LEDR 1 digitalWrite
\ NinaPin_LEDR 0 digitalWrite

