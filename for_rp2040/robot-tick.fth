\ ukmarsbot_forth
\ (c) 2022-2023 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: Robot tick for RP2040 on Zeptoforth

\ References:
\  - Inside Zeptoforth release: docs/words/timer.html#set-alarm
\  - https://github.com/tabemann/zeptoforth/discussions/57


\ task import
\ systick import

\ Our delay
\ 2500 constant our-delay-ticks

\ : non-slip-test
\   0 [:
\     systick-counter 0 { start-tick counter }
\     begin
\       our-delay-ticks start-tick current-task delay
\       counter .
\       1 +to counter
\       our-delay-ticks +to start-tick
\     again
\   ;] 320 128 512 spawn run
\ ;


timer import 

0 constant ROBOT-TICK-ALARM \ what timer 0-3 we are using from RP2040
variable max-robot-tick     \ the longest runtime in microseconds

\ Tick Time - it may still break for very small values of ROBOT-TICK-MICROSECS. 
\ However, for larger values like we are using here, it should be okay in 
\ most use cases ─ but it is still not guaranteed to work.
2000 constant ROBOT-TICK-MICROSECS

2 constant ROBOT-TICK-PRIORITY  \ @TODO review against systick priority

\ Alarm# and IRQ# happen to be the same
ROBOT-TICK-ALARM 0 + ( timer-irq ) constant robot-tick-irq
variable next-robot-tick

variable simple_tick

variable robot-tick-xt

: set-next-alarm
    \ set the next interrupt time
    
    \ ROBOT-TICK-MICROSECS next-robot-tick +!    \ simple version rather than loop

    \ more complex that deals with overrun
    begin
      ROBOT-TICK-MICROSECS next-robot-tick +!
      next-robot-tick @ us-counter-lsb - 0> dup not if

        \ optionally run it for every overrun, then recalculate next
        robot-tick-xt @ execute
      then
    until

    \ theoretical failure occurs when something happens between
    \ the if above and the set alarm...
    next-robot-tick @

    begin dup us-counter-lsb - 20 < while
        \ for very short gaps (potentially gone negative)
        \ bump forward slightly ( assuming 20 microseconds doesn't matter)
        20 +
    repeat

    \ if something happens (like a high priority interrupt) here
    \ then that might be a problem
    robot-tick-xt @ ROBOT-TICK-ALARM set-alarm
;

: robot-tick
    timer::us-counter-lsb   \ time when this interrupt started

    set-next-alarm

    \ clear this interrupt
    0 clear-alarm-int

    1 simple_tick +!

    ( do work here )
    enc_update

    \ store the longest duration
    timer::us-counter-lsb swap -
    dup max-robot-tick @ > if
        max-robot-tick !
    else
        drop
    then
;

: setup-robot-tick
    \ Set our priority for the IRQ
    ROBOT-TICK-PRIORITY 6 lshift robot-tick-irq NVIC_IPR_IP!

    0 max-robot-tick !
    0 simple_tick !
    ['] robot-tick robot-tick-xt !
    timer::us-counter-lsb next-robot-tick !
    set-next-alarm
;






