\ 16.16 Unsigned Fixed point Forth support
\ Written by Rob Probin May 2023
\ MIT License
\
\ Assumes a 16-bit cell size.
\
\ Fixed-point numbers are stored on the stack as ( fraction integer — )
\ This is on purpose so that they are like double-cell integers
-fixed16.16
marker -fixed16.16


: f+ ( frac2 int2 frac1 int1 — frac int ) d+ ;
: f-  ( frac2 int2 frac1 int1 — frac int ) d- ;

: f2* d2* ;
: f2/ d2/ ;

\ convert fixed point to single
: f>s ( frac int — int )  nip ;

\ convert a single cell integer to a frac
: s>f ( int - frac int)  0 swap ;

\ How multiplcation works
\ value1 = d1 * 2^-16
\ value2 = d2 * 2^-16
\ value1 * value2 = d1 * d2 * 2^-16 * 2^-16
\
\ Now in our case we are in two cells
\ d1 = d1.i * 2^16 + d1.f
\ d2 = d2.i * 2^16 + d2.f
\ So:
\ value1 * value2  = ((d1.i * 2^16 + d1.f) * 2^-16) * (d2.i * 2^16 + d2.f) * 2^-16)
\ value1 * value2  = (d1.i * 2^16 + d1.f) * (d2.i * 2^16 + d2.f) * 2^-16 * 2^-16
\
\ value1 * value2  = ((d1.f * d2.f) + (d1.f * d2.i * 2^16) + (d2.f * d1.i * 2^16) + (d1.i * 2 ^ 16 * d2.i * 2 ^ 16)) * 2^-32
\ value1 * value2  = ((d1.f * d2.f) + (d1.f * d2.i * 2^16) + (d2.f * d1.i * 2^16) + (d1.i * 2 ^ 32 * d2.i )) * 2^-32
\ value1 * value2  = 2^-32 * (d1.f * d2.f) + 2^-32*(d1.f * d2.i * 2^16) + 2^-32*(d2.f * d1.i * 2^16) + 2^-32*(d1.i * 2 ^ 32 * d2.i )
\ value1 * value2  = 2^-32 * (d1.f * d2.f) +           (d1.f * d2.i * 2^-16) +           (d2.f * d1.i * 2^-16) +          (d1.i *              d2.i )
\ 
\ since the fraction part has 2^-16 minimum, we can ignore (d1.f * d2.f)
\ 
\ Xd =  (d1.f * d2.i * 2^-16) +           (d2.f * d1.i * 2^-16) 
\ 
\ result.f = 0xFFFF & Xd		\ i.e. bottom bits
\ result.i =  (d1.i *              d2.i ) + Xd >> 16		( we could do rounding here by adding top bit of d1.f * d2.f)
\					                        Xd >> 16 is top bits of Xd

\ Multiply
: f* ( frac2 int2 frac1 int1 - frac int )  
    rot 2dup um* if ( overflow here ) then .s cr >r
    rot ( -- f2 f1 i1 i2   f2 i1 i2 f1 ) .s cr
    um* 2swap um* d+ ( -- f2 i2 f1 i1    Xd-frac Xd-int ) .s cr
    r> +
    ( count do rounding here) 
;

\ Function to calculate power of 10
\ do loop version
: powerOf10 ( n -- 10^n )
    1 swap
    ?dup if
        for \ 0 do
            10 *
        next \ loop
    then
;

\ Function to get the nth digit after decimal point
\ : getNthDigit_old ( fracPart n -- n' )
\     powerOf10 / 10 MOD 
\ ;

\ : emitDigit_old ( scaledFrac digit -- )
\   getNthDigit [char] 0 + emit
\ ;

\ : emitFrac_old ( Frac -- )
\   10000 65536 */
\   3 0 do
\     dup
\     3 I -
\     emitDigit
\   loop 
\ ;

\ test word when testing on machines that have a larger than 16-bit cell size
\ : dreduce-to-16bit-cell ( d d -- d16 d16 )
\   drop dup $ffff and swap #16 rshift
\ ;

\ test word when testing on machines that have a larger than 16-bit cell size
\ : um* um* dreduce_to-16-bit-cell ;

: emitDigit ( digit -- )
  [char] 0 + emit
;
\ FlashForth has these primatives in assembler
\ * ud* d2* 2* um*
\ u/mod u*/mod ud/mod um/mod
\ / u/ d2/ 2/
\ ud* Unsigned 32x16 to 32-bit multiply. ( ud u — ud )
\ um* Unsigned 16x16 to 32 bit multiply. ( u1 u2 — ud )
: emitFrac ( Frac digits -- )
  for \ 0 do
    #10 um* emitDigit
    dup 0= if endit then \ leave then
  next \ loop 
  drop
;

: f. ( fract int -- )
   0 <# #s #> type
  ?dup if
    [char] . emit
    4 emitFrac
  then
;

: FracSep ( c -- flag )
      dup
      [char] . =
      swap 
      [char] , = or
;



\: get1 ( addr u -- addr u c true | addr u false )
\  dup 0= if
\    false
\  else
\    over c@ true
\  then
\;


\ convert a string as a fraction
: >frac ( addr u -- addr2 u2 frac )
  dup >r
  0 0 2swap >number ( 0 0 addr1 u1 — ud.l ud.h addr2 u2 )
  r> over - powerOf10 ( ud.l ud.h addr2 u2 power )
  >r 2swap drop
  0 swap r>
  um/mod nip   \ broken if remainder
;

\  0
\  begin
\    >r get1 r> swap
\  while
\    digit? ( addr u x char -- addr u x val)
\    if 
\       0 0 10 /
\       >r >r 1 /string r> r>
\    then
\  repeat
\;

: scan,. ( c-addr u -- c-addr len c-addr u2 )
  
;

\  Convert string to a fixed-point number. ( 0 0 addr1 u1 -- frac int addr2 u2 )
: >fixed
    scan,.  	\ Scan string until c is found. ( c-addr u c — caddr1 u1 )
    >number ( 0 0 addr1 u1 — ud.l ud.h addr2 u2 )
    dup if
      over c@ FracSep
      if
        >frac >r 2swap nip r> swap 2swap
      then
    then
;

\ : 1/f ( n — 1/n )
\  0 1 2swap f/
\ ;


\ 0
\ 1.0
\ .01
\ .125
\ 1234
\ 1234.
\ 2e2
\ 2e-2
\ -3
\ -3.5
\ -3.5e
\ -3.5e1
\ -3.5e-1
\ 1e10                      \ will overflow 16.16 fixed point, but will parse? Or quit
\ -1e10                     \ will overflow 16.16 fixed point, but will parse? Or quit
\ 1.234e10              \ will overflow 16.16 fixed point
\ -1.234e10            \ will overflow 16.16 fixed point
\ 3,5
\ 3,50
\ -3,4
\ ,0
\ 00.00
\ 
\ Invalid
\ 0-0
\ 0,,0
\ 0..0
\ 0_

 

