\ Display stuff on 0.96" OLED Display Module (128x64) from Pi Hut
\ It is an I2C devices with SCL and SDA
\ This is driven by the popular SSD1306.
\ https://thepihut.com/products/0-96-oled-display-module-128x64?variant=42810024820931
\
\ For this to work you need to have done:
\ compile-to-flash
\ utils/codeload3.sh -B 115200 -p /dev/cu.usbmodem21401 serial extra/common/ssd1306_all.fs
\ compile-to-ram
\ reboot

oo import
bitmap import
ssd1306 import
font import
simple-font import
bitmap-utils import


\ An I2C SSD1306 device
<ssd1306> class-size buffer: my-ssd1306

\ The number of columns
128 constant my-cols

\ The number of rows
64 constant my-rows

\ My framebuffer size
my-cols my-rows bitmap-buf-size constant my-buf-size

\ My framebuffer
my-buf-size buffer: my-buf

\ Are we initialized
false value inited?

\ Initialize the test
\ Set up I2C and the pins we're using for it
: init-test ( -- )
12 13 my-buf my-cols my-rows SSD1306_I2C_ADDR 0 <ssd1306> my-ssd1306 init-object
init-simple-font
;

\ Draw text
: draw-text { c-addr u col row -- }
    inited? not if init-test true to inited? then
    c-addr u col row op-set my-ssd1306 a-simple-font draw-string
    my-ssd1306 update-display
;

: draw-line { x1 y1 x2 y2 -- }
    inited? not if init-test true to inited? then
    $FF x1 y1 x2 y2 op-set my-ssd1306 draw-pixel-line
    my-ssd1306 update-display
;

: draw-rect { x y x2 y2 -- }
    inited? not if init-test true to inited? then
    $FF 4 4 x y x2 y2 op-set my-ssd1306 draw-rect-line
    my-ssd1306 update-display
;




: display_test
    inited? not if init-test true to inited? then

    \ Clear the display first
    \ display.fill(0) 
    my-ssd1306 clear-bitmap

    \ Write a line of text to the display
    S" UKMARSBot" 0 0 draw-text 
    S" Rob Probin" 0 12 draw-text
    S" Zeptoforth" 20 24 draw-text

    \ Update the display
    my-ssd1306 update-display
;


