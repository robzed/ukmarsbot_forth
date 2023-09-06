\ ABC notation decoder by Rob Probin, August 2023.
\ Ported from Forlorn Fox version in Lua (also Copyright Rob Probin)
\
\ USE WITH: Zeptoforth RP2040 zeptoforth_full-1.x.x.uf2
\
\ MIT License
\
\ Copyright (c) 2023 Rob Probin
\ 
\ Permission is hereby granted, free of charge, to any person obtaining a copy
\ of this software and associated documentation files (the "Software"), to deal
\ in the Software without restriction, including without limitation the rights
\ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
\ copies of the Software, and to permit persons to whom the Software is
\ furnished to do so, subject to the following conditions:
\ 
\ The above copyright notice and this permission notice shall be included in all
\ copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
\ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
\ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
\ AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
\ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
\ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
\
\ ABC Notation Summary:
\ =====================
\
\  C = middle C
\  C, = octive below middle C
\  c = octive above middle C
\  c' = two octives above middle C
\  B, = note below middle C
\  CDEFGABcd
\  lengths A/8 A/4 A/2 A/ A A2 A3 A4 A6 A7 A8 A12 A15 A16
\  accidentals __A _A =A ^A ^^A   (Applies to that note to the end of the measure)
\  z = rest
\  Order for one note is <guitar chords>, <accents> (e.g. roll, staccato marker or up/downbow), <accidental>, <note>, <octave>, <note length>, e.g. ~^c'3 or even "Gm7"v.=G,2. 
\ 
\ ABC Notation
\ http://en.wikipedia.org/wiki/ABC_notation
\ http://abcnotation.com/examples
\ http://www.lesession.co.uk/abc/abc_notation.htm
\ http://trillian.mit.edu/~jc/doc/doc/ABCprimer.html

begin-module ABC-decoder
    begin-module ABC-internals

    12 constant notes_per_octive
    variable song_str
    variable song_len
    variable note_n
    variable note_modifier  \ they become accidentials for the rest of the bar
    variable note_modifier_set
    variable note_len
    variable note_fraction
    notes_per_octive cells buffer: note_accidentals


    \ Piano key frequencies
    create piano_key_freq
    261,6256 , , \ middle C 
    277,1826 , , \ C# / Db
    293,6648 , , \ D
    311,1270 , , \ D# / Eb
    329,6276 , , \ E
    349,2282 , , \ F
    369,9944 , , \ F#/Gb
    391,9954 , , \ G
    415,3047 , , \ G#/Ab
    440,0000 , , \ A
    466,1638 , , \ A#/Bb
    493,8833 , , \ B

    \ Stupid programmers are inconsistent between languages
    \ https://torstencurdt.com/tech/posts/modulo-of-negative-numbers/
    : modulo ( a b -- a%b )
    dup -rot    ( save b )
    mod
    dup 0< if + else nip then
    ;

    : base_freq ( note - freq )
    12 modulo CELLS 2* piano_key_freq + 2@
    ;

    : 2^n ( u -- f )
    1 swap lshift s>f
    ;

    end-module> import

: note_to_freq ( note -- Ffreq )
    dup base_freq
    rot dup 0 >= if
    12 /
    \ dup 0= if drop exit then
    2^n     \ 2^octive
    f*
    else
        11 - negate 12 / 2^n  \ 2^octive
        f/
    then
;

create local_note_table
     9 , \ A above middle C
    11 , \ B above middle C
     0 , \ middle C
     2 , \ D
     4 , \ E
     5 , \ F
     7 , \ G

\     C = 0  = middle C
\    D = 2
\    E = 4
\    F = 5
\    G = 7
\    A = 9
\    B = 11
\
\    c = 12
\    d = 14
\    e = 16
\    f = 17
\    g = 19
\    a = 21
\    b = 23


: decode_note ( c -- n )
    \ assume ascii
    dup [CHAR] a >= if
        12
    else
        0
    then
    swap ( -- octive c )
    to-upper-char
    [CHAR] A - cells local_note_table + @
    +   \ add on lower case offset next octive
;

: process_accidentials ( note -- modifier )
    \ remove the octive offset, if there is one
    dup notes_per_octive >= if
        notes_per_octive -
    then
    cells note_accidentals +     ( note-one-octive -- note_accidenials_address )

    \ now check if are are writing a new note modifier, or we 
    note_modifier_set @ if
        note_modifier @ swap !
        note_modifier @
    else
        \ get the existing note accidential
        @
    then
;

: do_note (  c -- )
    dup .
    decode_note
    dup .

    \ sort out note modifier first
    dup process_accidentials

    dup .

    \ note + modifier becomes the note
    + note_n !
;

99999 constant rest_note

: do_down_1_octive ( -- )
    note_n @ rest_note <> if
        -12 note_n +!
    then
;

: do_up_2_octives ( -- )
    note_n @ rest_note <> if
        24 note_n +!
    then
;

: do_sharp ( -- )
    1 note_modifier +!
    true note_modifier_set !
;

: do_natural ( -- )
    0 note_modifier !
    true note_modifier_set !
;

: do_flat ( -- )
    -1 note_modifier +!
    true note_modifier_set !
;

: do_rest ( -- )
    rest_note note_n !
;

: do_number ( c -- )
    dup [CHAR] / = if
        drop
        true note_fraction !
    else
        [char] 0 -
        note_len @ 10 * 
        +
        note_len !
    then
;

: do_barline ( c -- )
    \ applies to this measure(=bar) only
    notes_per_octive 0 do
        0 note_accidentals I cells + !
    loop
;


: finish_number ( -- float )
    note_fraction @ if
        note_len @ 0 = if
            \ '/' is same as /2
            0,5
        else
            1,0 note_len @ s>f f/
        then
    else
        note_len @ 0 = if
            1,0
        else
            note_len @ s>f
        then
    then
;

: new_note ( -- )
    0 note_modifier !
    false note_modifier_set !
    false note_fraction !
    rest_note note_n !
    0 note_len !
;


: ABC_decoder ( music_string music_len -- ) 
    song_len !
    song_str !

    new_note

    notes_per_octive 0 do
        0 note_accidentals I cells + !
    loop

;

: ABC_next ( -- c | -1 )
    \ return 0 if no more
    song_len @ 0= if 
        -1
    else 
        -1 song_len +!
        song_str @ C@
        1 song_str +!
    then
;

: ABC_skip_spaces ( -- c )
    bl
    begin
        drop
        ABC_next 
        dup bl <>
    until
;

: str@ ( str len -- str+1 len-1 c )
    over c@
    -rot
    1-
    swap
    1+
    swap
    rot
; 

: match ( str len c -- false | char true )
    begin
        over 0>
    while
        >r
        str@
        r@
        = if
            2drop
            r> true exit
        else
            r>
        then
    repeat
    drop 2drop false
;

: ABC_back_one
    1 song_len +!
    -1 song_str +!
;

\ note breaks if length of ABC string is zero due to ABC_back_one
: one_of ( str len -- false | char true )
    
    ABC_skip_spaces 
    \ -1 means end of string - we should immediately drop out 
    dup -1 = if
        drop 2drop false exit
    then

    ( str len c )
    match
    dup false = if
        \ rewind that character
        ABC_back_one
    then
;

: guitar-chords
    \ we don't support this yet
    \ "Gm7"
;

: fiddle-bowing
    \ we don't support these yet
    \ u (up-bow) and v (down-bow)
;

: accents
    \ we don't support these yet
    \ e.g. staccato .
;

: accidental ( -- )
    \ _ __ ^ ^^ =
    \ __A _A =A ^A ^^A   (Applies to that note to the end of the measure)
    begin
        S" _^=" one_of
    while
        dup [CHAR] = = if
            do_natural 
        else
            dup [CHAR] ^ = if
                do_sharp
            else
                dup [CHAR] _ = if
                    do_flat
                else
                    ." accidental missing" CR
                then
            then
        then
        drop
    repeat
;
: base-note ( -- flag ) 
    \ CDEFGABcdefgab 
    \ but also rest
    \ z
    S" CDEFGABcdefgabz" one_of if
        dup [CHAR] z = if
            drop do_rest 
        else
            do_note
        then
        true
    else
        false
    then
;

: octave
    \ , '
    \ C,D,E,F,G,A,B,CDEFGABcdefgabc'd'e'f'g'a'b' 
    \ can be extended further by adding more commas or apostrophes

    begin
        S" '," one_of
    while
        [CHAR] ' = if
            do_up_2_octives
        else
            \ assume ,
            do_down_1_octive
        then
    repeat
;

: note-length
    \ / and numbers
    \  A/8 A/4 A/2 A/ A A2 A3 A4 A6 A7 A8 A12 A15 A16
    begin
        S" /1234567890" one_of
    while
        do_number
    repeat
;

: barlines
    \ pipe symbol |
    \ don't have an effect on the music, except to cancel accidentals
    S" |" one_of if drop do_barline then
;


: get_note ( -- false | float-Duration float-freq true )
    new_note
    barlines 
    guitar-chords fiddle-bowing accents accidental
    base-note false = if
        false exit
    then
    octave note-length
    finish_number
    note_n @ rest_note = if
        0,0
    else
        note_n @ note_to_freq
    then

    true
;

: ABC_play ( -- )
    begin
        get_note
    while
        ." dur=" f. ." freq=" f. cr
    repeat
;

: ABC_test ( -- )
  \ for testing - Notice the accident holds in a bar
  \ http://www.onlinesheetmusic.com/if-i-were-a-rich-man-p110718.aspx
  \ Jetset in game tune :-)
  S" | GFGF E2C2 | z2 EF GFGF  | EFGA _BABA | G2 z6 | _A2G2 _G2F2 | _EDCD E2z2 | _EDCD E2C2 | G2 z6 |"
 
  ABC_decoder
  \ ABC_play
;


end-module

