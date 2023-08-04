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
    systicks import

    9 constant NINA_CS
    10 constant NINA_READY
    3 constant NINA_RESET
    2 constant NINA_GPIO0   \ same as NINA_IRQ
    2 constant NINA_IRQ     \ same as NINA_QPIO0

    \ false value SPI_init_f

    : SPI_slave_deselect ( -- )
        high NINA_CS pin!
    ;

    : time_start ( milliseconds-to-expire -- timeVal )
       10 * systick-counter +
    ;
    : time_expired ( timeVal -- )
        systick-counter <
    ;

    : SPI_slave_select ( -- )
        low NINA_CS pin!
        \ wait for 5ms in case Nina is not ready yet
        \ timeout will be module broken/missing
        \ wait for slave ready
        5 time_start begin dup time_expired NINA_READY pin@ or until drop
    ;

    : SPI_wait_for_slave_ready ( -- )
        20 time_start begin dup time_expired NINA_READY pin@ or until drop
    ;

    : SPI_setup ( -- )

        NINA_CS output-pin \ SPI slave select
        NINA_READY input-pin
        NINA_RESET output_pin
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
        true false 1 motorola-spi
        1 enable-spi

        \ true to Spi_init_f
    ; 

    : SPI_wait_for_SS  ( -- )
        \ SPI_init_f 0= if
        \    SpiSetup 
        \ then
        SPI_wait_for_slave_ready
        SPI_slave_select
    ;

    : SPI_send ( byte -- )
        1 >spi 1 spi> drop 
    ;

    : SPI_read_8 ( -- u8 )
        0 1 >spi 1 spi>
    ; 

    : SPI_read_be16 ( -- u16 )
        SPI_read_8 8 lshift
        SPI_read_8 +
    ;

    : SPI_check_start_cmd ( -- success )
        \ @TODO add code
    ;

    : SPI_check_data ( data -- success )
        \ @TODO add code
    ; 

    : SPI_get_response_cmd ( params commnd -- [ n .. n+params ]  ) 
        SPI_check_start_cmd if
            REPLY_FLAG + SPI_check_data drop    \ ignore    @TODO check

            \ check correct number of params
            SPI_check_data if
            SPI_read_8 0 ?do 
                \ Get Params data
                SPI_read_be16
                loop
            else
                0 exit
            then

            END_CMD readAndCheckChar
        else
            drop 0  \ no version
        then
    ;

    : SPI_send_cmd ( params command -- )
        START_CMD SPI_send
        SPI_send    \ top bit should be clear (REPLY_FLAG)
        \ no total length in this packet
        dup SPI_send \ #params
        0= if END_END SPI_send then
    ;

    : SPI_send_param (lastParam? param -- )
        \ Send SPI paramLen
        2 SPI_send

        \ big-endian parameter
        dup 8 rshift SPI_send
        $ff and SPI_send

        if END_CMD SPI_send then
    ;

    end-module> import


    : enable_NINA ( -- )
        SPI_setup
    ; 

    : toAnalogPin ( pin -- ch )
        dup 4 = if drop 6 exit then \ ch 6 on ADC1
        dup 5 = if drop 3 exit then \ ch 3 on ADC1
        dup 6 = if drop 0 exit then \ ch 0 on ADC1
        dup 7 = if drop 7 exit then \ ch 7 on ADC1
        drop $FF
    ;

    : pinMode ( pin mode -- )
    ;
    
    : digitalRead ( pin -- state )
    ;

    : digitalWrite ( pin state -- )
        \ inverted state 0 or 1 to NINA
        0= if then 1 else 0 then
        
    ;

    : analogRead ( pin -- value )
        toAnalogPin
    ;


    : analogWrite ( pin value -- )
    ;

    : getFwVersion ( -- version )
        SPI_wait_for_SS
        0 GET_FW_VERSION_CMD SPI_send_cmd

        SPI_slave_deselect

        \ Wait the reply elaboration
        SPI_wait_for_slave_ready
        SPI_slave_select

        uint8_t _dataLen = 0;
        1 GET_FW_VERSION_CMD SPI_get_response_cmd
        SPI_slave_deselect
    ;


end-module

