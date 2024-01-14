\ systick
\ (c) 2023 Rob Probin
\ MIT License, see LICENSE file
\ 
\ On the Arduino Nano ATMeta328P uses Timer 2
\ Timer 0 is usually used by FlashForth for the millisecond timing.
\ (A similar situation occurs with the Arduino Framework)

0systick  \ make sure interrupts are disabled before replacing
-SysTick
marker -SysTick


decimal

: mask ( bit -- mask ) 1 swap lshift ; 

$70 constant TIMSK2 \ 8 bit Timer/Counter2 Interrupt Mask Register
\ TOIE2 0
1 mask constant OCIE2A
\ OCIE2B 2

$b0 constant TCCR2A \ 8 bit Timer/Counter2 Control Register A
0 mask constant WGM20
1 mask constant WGM21
\ COM2B0 4
\ COM2B1 5
\ COM2A0 6
\ COM2A1 7

$b1 constant TCCR2B \ 8 bit Timer/Counter2 Control Register B
0 mask constant CS20
1 mask constant CS21
2 mask constant CS22
3 mask constant WGM22
\ FOC2B 6
\ FOC2A 7

$b3 constant OCR2A \ 8 bit Output Compare Register 2 A

\ vector for timer 2 comparison
8 constant TIMER2_COMPA_v

defer systick_update

: systick_isr
  \ This could be a long interrupt so
  \ make sure we don't lose encoder interrupt
  ei  \ Ensure ISR is not blocking

  systick_update
;i



: systick_dummy ;

: systick_init

  ['] systick_dummy is systick_update

  ['] systick_isr TIMER2_COMPA_v int!

  \ Clear Timer on Compare Match (CTC) mode
  WGM20 TCCR2A mclr
  WGM21 TCCR2A mset
  WGM22 TCCR2B mclr
  \ set divisor to 128 => 125kHz
  CS22 TCCR2B mset
  CS21 TCCR2B mclr
  CS20 TCCR2B mset
  249 OCR2A c!  \ (16000000/128/500)-1 => 500Hz
  OCIE2A TIMSK2 mset

  \ make sure it runs for a few cycles before we continue
  10 ms 
;

: 0systick  OCIE2A TIMSK2 mclr ; 

\ test routines
\ 
\ : show_regs
\   bin
\   ." TCCR2A=" TCCR2A c@ u. cr
\   ." TCCR2B=" TCCR2B c@ u. cr
\   decimal
\   ." OCR2A=" OCR2A c@ . cr
\ ;
\ 
\ variable myticks
\ 0 myticks !
\ : inc_myticks 1 myticks +! ;
\ 
\ : run ['] inc_myticks is systick_update ;
\ : .t myticks @ . ;
\ : 1sec myticks @ 1000 ms myticks @ swap - . ;
\ 

