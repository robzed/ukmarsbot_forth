\ ukmarsbot_forth
\ (c) 2022 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: Deals with the encoders

\ Based on  ukmars mazerunner core

\ 0encoders
\ -encoders
\ marker -encoders

\ 
\ These are fixes for the Zeptoforth routines until we get replacement fixed Zeptoforth
\ 
    $40014000 constant IO_BANK0_BASE
    
    \ GPIO processor 0 interrupt enable registers
    IO_BANK0_BASE $100 + constant PROC0_INTE0
    IO_BANK0_BASE $0F0 + constant INTR0
    IO_BANK0_BASE $120 + constant PROC0_INTS0

  \ Set an edge low interrupt enable for processor 0
  : _PROC0_INTE_GPIO_EDGE_LOW! ( enable index -- )
    dup 7 and 2 lshift 2 + bit swap 1 rshift $c and PROC0_INTE0 +
    rot if bis! else bic! then
  ;

  \ Set an edge high interrupt enable for processor 0
  : _PROC0_INTE_GPIO_EDGE_HIGH! ( enable index -- )
    dup 7 and 2 lshift 3 + bit swap 1 rshift $c and PROC0_INTE0 +
    rot if bis! else bic! then
  ;

  \ Clear a raw edge low interrupt
  : _INTR_GPIO_EDGE_LOW! ( index -- )
    dup 7 and 2 lshift 2 + bit swap 1 rshift $c and INTR0 + !
  ;

  \ Clear a raw edge high interrupt
  : _INTR_GPIO_EDGE_HIGH! ( index -- )
    dup 7 and 2 lshift 3 + bit swap 1 rshift $c and INTR0 + !
  ;

  \ Get an edge low interrupt status for processor 0
  : _PROC0_INTS_GPIO_EDGE_LOW@ ( index -- enable )
    dup 7 and 2 lshift 2 + bit swap 1 rshift $c and PROC0_INTS0 + bit@
  ;

  \ Get an edge high interrupt status for processor 0
  : _PROC0_INTS_GPIO_EDGE_HIGH@ ( index -- enable )
    dup 7 and 2 lshift 3 + bit swap 1 rshift $c and PROC0_INTS0 + bit@
  ;



\ Variables
\ =========

\ None of the variables in this file should be directly available to the rest
\ of the code without a guard to ensure atomic access. 

fvariable my_distance
fvariable my_angle

\ the change in distance or angle in the last tick.
fvariable fwd_change
fvariable rot_change

\ internal use only to track encoder input edges
variable left_count
variable right_count


\ define the pins
\ ===============

25 constant ENC_LEFT_CLK   \ Nano D2
15 constant ENC_RIGHT_CLK  \ Nano D3
16 constant ENC_LEFT_B     \ Nano D4
17 constant ENC_RIGHT_B    \ Nano D5
0 constant ENCODER_GPIO_PRIORITY

pin import
interrupt import

\ Interrupt Service routines
\ ==========================

\ The ISR will respond to the XOR-ed pulse train from the encoder - i.e. 
\ both rising and falling interrupts

\ These are called on quite a high freqency for the ATmega328, so we 
\ need to be careful we only do the minimum possible. The calculation
\ work is done by a slower interrupt - like a 2ms timer interrupt.

\ left input change - interrupt service routine
variable l_oldA
variable l_oldB
: left_isr
    ENC_LEFT_B pin@
    ENC_LEFT_CLK pin@ over xor \ fix the A-xor-B input to A only.
    2dup
    \ we need to check the ENCODER_POLARITY * ((oldA ^ newB) - (newA ^ oldB));
    swap l_oldA @ xor ( newB newA newB newA -- newB newA newA newB^oldA )
    swap l_oldB @ xor (  -- newB newA newB^oldA newA^oldB )
    - ENC_LEFT_POL * ( -- newB newA delta )
    left_count +!   \ add delta onto counter

    \ store for next interrupt
    l_oldA !
    l_oldB !
;

\ right input change - interrupt service routine
variable r_oldA
variable r_oldB
: right_isr
    ENC_RIGHT_B pin@
    ENC_RIGHT_CLK pin@ over xor \ fix the A-xor-B input to A only.
    2dup
    \ we need to check the ENCODER_POLARITY * ((oldA ^ newB) - (newA ^ oldB));
    swap r_oldA @ xor ( newB newA newB newA -- newB newA newA newB^oldA )
    swap r_oldB @ xor (  -- newB newA newB^oldA newA^oldB )
    - ENC_RIGHT_POL * ( -- newB newA delta )
    right_count +!   \ add delta onto counter

    \ store for next interrupt
    r_oldA !
    r_oldB !
;

gpio import

\ allows us to chain the handlers
variable old-io-handler
\ This is the IRQ number for IO_IRQ_BANK0
13 constant io-irq
\ interrupt table is directly after the 16 arm exception vectors
io-irq 16 + constant io-vector



: gpio-change-isr
    old-io-handler @ execute    \ chain other GPIO change interrupts, usually only default
    ENC_LEFT_CLK _PROC0_INTS_GPIO_EDGE_HIGH@ ENC_LEFT_CLK _PROC0_INTS_GPIO_EDGE_LOW@ or if
      left_isr ENC_LEFT_CLK _INTR_GPIO_EDGE_HIGH! ENC_LEFT_CLK _INTR_GPIO_EDGE_LOW!
    then
    ENC_RIGHT_CLK _PROC0_INTS_GPIO_EDGE_HIGH@ ENC_RIGHT_CLK _PROC0_INTS_GPIO_EDGE_LOW@ or if
      right_isr ENC_RIGHT_CLK _INTR_GPIO_EDGE_HIGH! ENC_RIGHT_CLK _INTR_GPIO_EDGE_LOW!
    then

;

: register-my-gpio-handler ( -- )
  io-vector interrupt::vector@ old-io-handler !
  true ENC_LEFT_CLK _PROC0_INTE_GPIO_EDGE_HIGH! true ENC_LEFT_CLK _PROC0_INTE_GPIO_EDGE_LOW!
  true ENC_RIGHT_CLK _PROC0_INTE_GPIO_EDGE_HIGH! true ENC_RIGHT_CLK _PROC0_INTE_GPIO_EDGE_LOW!
  ['] gpio-change-isr io-vector interrupt::vector!

  \ Set our priority for the GPIO IRQ
  ENCODER_GPIO_PRIORITY 6 lshift io-irq NVIC_IPR_IP!

  \ Enable the GPIO IRQ
  io-irq NVIC_ISER_SETENA!
;


\ General Words
\ =============

: enc_reset
    \ atomic block
    di
    0 left_count !
    0 right_count !
    0 my_distance !
    0 my_angle !
    ei
;

\ this update function should be called from the periodic timer interrupt
\ The rate should be LOOP_FREQ.
\ 
: enc_update
    right_count left_count
    \ Make sure values don't change while being read. Be quick.
    di
        @ swap @
        0 left_count !
        0 right_count !
    ei
    ( left_count right_count )

    \ calculate the change in micrometers
    mm/COUNT_RIGHT *
    swap
    mm/COUNT_LEFT *
    ( right left -- )

    \ forward is sum
    \ rotation is difference
    2dup
    + s>f 0,5 f/ fwd_change f!
    - s>f DEG/mm_DIFFERENCE * rot_change f!

    \ update cumulatives figures
    my_distance @ fwd_change @  f+ my_distance f!
    my_angle @ rot_change @ f+ my_angle f!
;

: 0encoders
  io-irq NVIC_ICER_CLRENA!
  false ENC_LEFT_CLK _PROC0_INTE_GPIO_EDGE_HIGH! false ENC_LEFT_CLK _PROC0_INTE_GPIO_EDGE_LOW!
  false ENC_RIGHT_CLK _PROC0_INTE_GPIO_EDGE_HIGH! false ENC_RIGHT_CLK _PROC0_INTE_GPIO_EDGE_LOW!
  old-io-handler @ io-vector interrupt::vector!
;

: enc_setup
    \ just in case previously enabled
    io-irq NVIC_ICER_CLRENA!

    0 l_oldA !
    0 l_oldB !
    0 r_oldA !
    0 r_oldB !
    ENC_LEFT_CLK input-pin
    ENC_LEFT_B input-pin
    ENC_RIGHT_CLK input-pin
    ENC_RIGHT_B input-pin
    enc_reset
    register-my-gpio-handler
;


\ these access the variables in a safe manner
: robot-distance ( -- distance distance )
    my_distance di f@ ei
;

: robot-speed ( -- speed )
    fwd_change di f@ ei
    LOOP_FREQ f*
;

: robot-omega ( -- omega )
    rot_change di @ ei
    LOOP_FREQ f*
;

: robot-fwd-change@  ( -- distance )
    fwd_change di @ ei
;

: robot-rot-change@ ( -- distance )
    rot_change di f@ ei
;

: angle ( -- angle angle )
    my_angle di f@ ei
;

