\ ukmarsbot_forth
\ (c) 2022-2023 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: Main for RP2040 on Zeptoforth


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

0 constant ROBOT-TICK-ALARM
variable max-robot-tick
2000 constant ROBOT-TICK-MICROSECS
variable next-robot-tick

variable simple_tick

variable robot-tick-xt

: set-next-alarm
    \ set the next interrupt time
    ROBOT-TICK-MICROSECS next-robot-tick +!
    next-robot-tick @
    robot-tick-xt @ ROBOT-TICK-ALARM set-alarm
;

: robot-tick
    timer::us-counter-lsb   \ time when this interrupt started

    set-next-alarm

    \ clear this interrupt
    0 clear-alarm-int


    1 simple_tick +!

    \ store the longest duration
    timer::us-counter-lsb swap -
    dup max-robot-tick @ > if
        max-robot-tick !
    else
        drop
    then
;

: setup-robot-tick
    0 max-robot-tick !
    0 simple_tick !
    ['] robot-tick robot-tick-xt !
    timer::us-counter-lsb next-robot-tick !
    set-next-alarm
;

: main ( -- )
    setup-robot-tick
;




