\ ukmarsbot_forth
\ (c) 2022-2023 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: Robot ADC for RP2040 on Zeptoforth

begin-module robot-core-adc

gpio import
adc import
adc-internal import

begin-module robot-adc-internal

    \ fifo size before IRQ triggered
    4 constant ROBOT_ADC_#FIFO
    
    \ FIFO and Interrupt registers
    ADC_BASE $08 + constant ADC_FCS
    ADC_BASE $0C + constant ADC_FIFO
    ADC_BASE $18 + constant ADC_INTE

    : ADC_CS_RROBIN! ( mask -- )
        ADC_CS @ [ $1F #16 lshift ] literal bic
        swap #16 lshift or ADC_CS !
    ;

    : ADC_CS_START_MANY! ( flag -- ) 3 bit ADC_CS rot if bis! else bic! then ;

    : ADC_FCS_THRESH! ( n -- ) 
        ADC_FCS @ [ $F #24 lshift ] literal bic
        swap #24 lshift or ADC_FCS !
    ;
    : ADC_FCS_EN! ( flag -- )  0 bit ADC_FCS rot if bis! else bic! then ;
    : ADC_INTE_EN! ( flag -- ) 0 bit ADC_INTE rot if bis! else bic! then ;
    : ADC_FCS_LEVEL@ ( -- n ) ADC_FCS @ #16 rshift $F and ;
    : ADC_FCS_ERR! ( flag -- ) 2 bit ADC_FCS rot if bis! else bic! then ;

    9 bit constant ADC_FIFO_ERR
end-module> import


: stop4adc ( -- )
    false ADC_CS_START_MANY!
    false ADC_FCS_EN!
;

: get_samples ( -- n )
    ADC_FCS_LEVEL@
;

: get1of4adc ( -- n error )
    ADC_FIFO @ dup adc-max and swap ADC_FIFO_ERR and
;

: start4adc ( -- ) 
    true ADC_FCS_ERR!   \ have conversion error alongside result
    0 ADC_CS_AINSEL!
    $f ADC_CS_RROBIN!   \ first 4 channels
    ROBOT_ADC_#FIFO ADC_FCS_THRESH!
    true ADC_INTE_EN!
    true ADC_FCS_EN!
    true ADC_CS_START_MANY!
;

: _disable_IO ( pin -- )
    false over PADS_BANK0_IE!
    true swap PADS_BANK0_OD!
;

: init-robot-adc-core
    \ disable the OE and IE for the 4 ADC ports
    \ As per 4.9.1. Features in RP2040 Datasheet
    26 _disable_IO
    27 _disable_IO
    28 _disable_IO
    29 _disable_IO

    \ turn off the temperature sensor?
    \ false ADC_CS_TS_EN!
;


: adc-status
    cr ." ADC CS=" ADC_CS @ dup binary . hex . decimal 
    cr ." ADC FCS=" ADC_FCS @ dup binary . hex . decimal 
;
end-module


\
\ Robot specific stuff
\
begin-module robot-adc


pin import
interrupt import
robot-core-adc import

\ NOTICE relationship between ROBOT_ADC_CH and that loaded into ADC_CS_RROBIN!
8 constant ROBOT_ADC_CH     \ must be a power of 2. We swapped from 4 to 8 to see ADC reading differences.
7 constant EMITTER_A        \ for 4 sensor wall - front emitters, or LED
4 constant EMITTER_B        \ for 3 sensor wall - 3 emitters, for 4 sensor wall - diagonal emitters

variable adc_mode
ROBOT_ADC_CH cells buffer: dark_adc
ROBOT_ADC_CH cells buffer: light_adc

\ prority of interrupt is same as tick timer (or lower)
2 constant ENCODER_ADC_PRIORITY

\ allows us to chain the handlers
\ variable old-io-handler
\ This is the IRQ number for IO_IRQ_BANK0
22 constant adc-fifo-irq
\ interrupt table is directly after the 16 arm exception vectors
adc-fifo-irq 16 + constant adc-fifo-vector

: read-adc-fifo ( address -- )
    >r
    0   \ index
    begin
        get_samples  
    while
        get1of4adc if
            \ error
            drop
        else
            over cells r@ + !
        then
        1+ ROBOT_ADC_CH 1- and
    repeat
    rdrop drop
;

variable emitter_enabled

: robot_adc_irq
    stop4adc
    adc_mode @ 0= if
        dark_adc read-adc-fifo
        \ turn on LED(s)
        emitter_enabled @
        dup EMITTER_B pin!
            EMITTER_A pin!
        start4adc
    else
        light_adc read-adc-fifo
        \ turn off LED(s)
        false EMITTER_B pin!
        false EMITTER_A pin!
    then
    1 adc_mode +!
;

\ should only be called from tick interrupt
: start_conversion
    0 adc_mode !
    start4adc
;

: erase_results
  dark_adc 4 0 do 0 over I CELLS + ! loop drop 
  light_adc 4 0 do 0 over I CELLS + ! loop drop 
;

: init_robot-adc
    false emitter_enabled !
    erase_results
    1 adc_mode !
    init-robot-adc-core

    \ Set our priority for the GPIO IRQ
    ENCODER_ADC_PRIORITY 6 lshift adc-fifo-irq NVIC_IPR_IP!

    \ install our vector
    ['] robot_adc_irq adc-fifo-vector interrupt::vector!

    \ Enable the GPIO IRQ
    adc-fifo-irq NVIC_ISER_SETENA!

    \ setup emitter LED(s)
    EMITTER_A output-pin
    EMITTER_B output-pin
    \ turn off LED(s)
    false EMITTER_A pin!
    false EMITTER_B pin!
;

: get_light_adc ( n -- n ) CELLS light_adc + @ ;
: get_dark_adc ( n -- n ) CELLS dark_adc + @ ;

: get_sensor_level ( n -- n ) dup get_light_adc swap get_dark_adc - 1 max ;

: disable_emitters
    false emitter_enabled !
    false EMITTER_A pin!
    false EMITTER_B pin!
;

: enable_emitters
    false emitter_enabled !
; 

: show-sensors
  cr
  ROBOT_ADC_CH 0 do I get_dark_adc .l space loop cr
  ROBOT_ADC_CH 0 do I get_light_adc .l space loop cr
  ROBOT_ADC_CH 0 do I get_sensor_level .l space loop cr
;

: offline-adc-test
  enable_emitters

  \ only init the first time
  adc-fifo-irq NVIC_IPR_IP@ 6 rshift 2 <> if
      init_robot-adc
  then
  start_conversion
  10 ms
  show-sensors
  10 ms
  erase_results
  adc-status

  disable_emitters
;

end-module> import


