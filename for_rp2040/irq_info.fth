\ Visualise RP2040 Interrupts
\ (c) 2022 Rob Probin 
\ MIT License, see LICENSE file
\ 

interrupt import
decimal
.s
: .HEX ( n cnt -- ) HEX  <# 0 DO # LOOP #> TYPE DECIMAL ;
: .B 0 2 .HEX ;
: .H 0 4 .HEX ;
: .L 0 8 .HEX ;

\ What IRQ relates to what interrupts?


: irq_priorities
    cr ." 0=high, 3=low" cr
    ." mem man fault " SHPR1_PRI_4@ 6 rshift . cr
    ." bus fault " SHPR1_PRI_5@ 6 rshift . cr
    ." usage fault " SHPR1_PRI_6@ 6 rshift . cr
    ." SVCall " SHPR2_PRI_11@ 6 rshift . cr
    ." PendSV " SHPR3_PRI_14@ 6 rshift . cr
    ." systick " SHPR3_PRI_15@ 6 rshift . cr

    32 0 do
        I ." IRQ" . I NVIC_IPR_IP@ 6 rshift . 3 spaces
        I 3 and 3 = IF cr THEN
    loop
;

: .bitpos ( data -- )
    32 0 do
        dup 1 rshift swap 1 and if ."  1" else ."  _" then
    loop
    drop
;


: irq_status
cr ."         " $10 0 do SPACE SPACE loop $10 0 do 1 . loop 
cr ."         " hex $10 0 do I . loop $10 0 do I . loop decimal
cr ." pending" NVIC_ISPR_Base @  .bitpos 
\ cr ." pending" NVIC_ICPR_Base @ .bitpos   \ same results as reading NVIC_ISPR
cr ." enabled" NVIC_ISER_Base @  .bitpos
\ cr ." enabled" NVIC_ICER_Base @  .bitpos  \ same results as reading NVIC_ISER
cr ." NMI proc0 " $40004000 @ .L
cr ." NMI proc1 " $40004004 @ .L
cr
cr ." 1=Low Level, 2=High Level, 4=Edge Low, 8=Edge High"
cr ." INTR07-00 " $400140f0 @ .L \ .bitpos8
cr ." INTR15-08 " $400140f4 @ .L \ .bitpos8
cr ." INTR23-16 " $400140f8 @ .L \ .bitpos8
cr ." INTR31-24 " $400140fc @ .L \ .bitpos8
cr ." INTE07-00 " $40014100 @ .L \ .bitpos8
cr ." INTE15-08 " $40014104 @ .L \ .bitpos8
cr ." INTE23-16 " $40014108 @ .L \ .bitpos8
cr ." INTE31-24 " $4001410c @ .L \ .bitpos8
cr ." INTS07-00 " $40014120 @ .L \ .bitpos8
cr ." INTS15-08 " $40014124 @ .L \ .bitpos8
cr ." INTS23-16 " $40014128 @ .L \ .bitpos8
cr ." INTS31-24 " $4001412c @ .L \ .bitpos8
cr
;

\ NVIC_ISPR_Base .L
\ NVIC_ICPR_Base .L
\ NVIC_ISER_Base .L
\ NVIC_ICER_Base .L


: irq_source
cr ." 0 TIMER_IRQ_0  6  XIP_IRQ    12 DMA_IRQ_1     18 SPI0_IRQ    24 I2C1_IRQ"
cr ." 1 TIMER_IRQ_1  7  PIO0_IRQ_0 13 IO_IRQ_BANK0  19 SPI1_IRQ    25 RTC_IRQ"
cr ." 2 TIMER_IRQ_2  8  PIO0_IRQ_1 14 IO_IRQ_QSPI   20 UART0_IRQ"
cr ." 3 TIMER_IRQ_3  9  PIO1_IRQ_0 15 SIO_IRQ_PROC0 21 UART1_IRQ"
cr ." 4 PWM_IRQ_WRAP 10 PIO1_IRQ_1 16 SIO_IRQ_PROC1 22 ADC_IRQ_FIFO"
cr ." 5 USBCTRL_IRQ  11 DMA_IRQ_0  17 CLOCKS_IRQ    23 I2C0_IRQ"
cr
;



