\ systick
\ On the Arduino Nano ATMeta328P uses Timer 2
\ Timer 0 is usually used by FlashForth for the millisecond timing.
\ (A similar situation occurs with the Arduino Framework)


varaible systick_next

: systick_isr
  systick_next @ execute
  \ manually clear the interrupt
  TCB2.INTFLAGS = TCB_CAPT_bm;
;i

: systick_dummy ;

: systick_init
    TCB2.CTRLA &= ~TCB_ENABLE_bm;      // stop the timer
    TCB2.CTRLA = TCB_CLKSEL_CLKTCA_gc; // Clock selection is same as TCA (F_CPU/64 -- 250kHz)
    TCB2.CTRLB = (TCB_CNTMODE_INT_gc); // set periodic interrupt Mode
    // timer is clocked at 250000Hz = 4us per tick
    TCB2.CCMP = 2000 / (1000000 / 250000) - 1; // we want 2000us => 5000 ticks
    TCB2.CTRLA |= TCB_ENABLE_bm;               // Enable & start
    TCB2.INTCTRL |= TCB_CAPT_bm;               // Enable timer interrupt

    ['] systick_dummy systick_next !

    \ make sure it runs for a few cycles before we continue
    10 ms 
;


\ Add a function to list the list called by 
: systick_add ( XT -- )
;


