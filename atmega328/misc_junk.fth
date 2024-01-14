\ bitSet/bitClear - not fast, but ok for setup routines
\ Faster is to use the mask directly with mset/mclr
: bitSet   ( bit addr -- ) swap mask swap mset ;
: bitClear ( bit addr -- ) swap mask swap mclr ;



variable myticks
0 myticks !
: inc_myticks 1 myticks +! ;

$26 constant TCNT0
$46 constant TCNT0_
$87 constant TCNT
$b2 constant TCNT2

: .t2 TCNT2 @ u. ;

: 1sec .t2 1000 ms .t2 ; 
: 1s TCNT2 @ 1000 ms TCNT2 @ swap - . ;

