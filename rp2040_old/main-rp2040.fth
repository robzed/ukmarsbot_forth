\ ukmarsbot_forth
\ (c) 2022-2023 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: Main for RP2040 on Zeptoforth


: encoder_view
    cr ." total =  " my_distance f@ f. ." mm  " my_angle f@ f. ." deg  " 
    cr ." change = " fwd_change f@ f. ." mm   " rot_change f@ f.  ." deg  "
;

: main ( -- )
    \ only init the first time
    adc-fifo-irq NVIC_IPR_IP@ 6 rshift 2 <> if
        init_robot-adc
    then
    enc_setup
    setup-robot-tick
;




