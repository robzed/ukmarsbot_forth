\ Board setup

-ukmarsBoard
marker -ukmarsBoard


\ Arduino Pin 13 = PB13 = Onboard LED
\ (Rob's board has a buzzer connected to this pin as well)
PORTB 5 defPIN: LED
\ PORTD 3 defPIN: BUTTON1
\ PORTC 5 defPIN: BUTTON3
\ PORTC 0 defPIN: BUTTON4
\ PORTB 3 defPIN: BUZZER


: init.ports ( --)
    LED output
    \ BUTTON1 input
    \ BUTTON1 high    \ enable pull ups
    \ BUTTON2 input \ analogue input
    \ BUTTON3 input
    \ BUTTON3 high    \ pu
    \ BUTTON4 input
    \ BUTTON4 high    \ pu
    \ BUZZER output
    \ BUZZER low      \ make sure turned off
  ;


: test_buttons ( -- )
    init.ports

    begin
        \ BUTTON1 pin@ 0= if ." Button1" cr then
        \ BUTTON3 pin@ 0= if ." Button3" cr then
        \ BUTTON4 pin@ 0= if ." Button4" cr then
        LED high
        100 ms
        LED low
        100 ms
        LED high
        100 ms
        LED low
        500 ms
        
    key? until
  ;

