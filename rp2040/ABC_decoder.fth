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
    notes_per_octive cells buffer: key_accidentials


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

: remove_octive_offset ( n -- n )
    dup notes_per_octive >= if
        notes_per_octive -
    then
;

: process_accidentials ( note -- modifier )
    \ remove the octive offset, if there is one
    remove_octive_offset
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
    decode_note

    \ sort out note modifier first
    dup process_accidentials


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

: do_barline ( -- )
    \ applies to this measure(=bar) only
    notes_per_octive 0 do
        \ copy from key accidentials to note accedentials
        key_accidentials I cells + @
        note_accidentals I cells + !
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

: clear_key ( -- )
\ this effectively sets C major, A minor
    notes_per_octive 0 do
        0 key_accidentials I cells + !
    loop
;

: ABC_decoder ( music_string music_len -- ) 
    song_len !
    song_str !

    new_note

    clear_key       \ set C major
    do_barline
;

: key-sharp ( c -- )
    decode_note remove_octive_offset
    cells key_accidentials +
    1 swap !
;
: key-flat ( c -- )
    decode_note remove_octive_offset
    cells key_accidentials + 
    -1 swap !
;


: a_minor_key ( -- )
    clear_key
    do_barline
;
: c_major_key ( -- )
    clear_key
    do_barline
;
: b_minor_key ( -- )
    clear_key
    [char] F key-sharp
    [char] C key-sharp
    do_barline
;
: g_major_key ( -- )
    clear_key
    [char] F key-sharp
    do_barline
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

\ (2 2 notes in the time of 3
\ (3 3 notes in the time of 2
\ (4 4 notes in the time of 3
\ (5 5 notes in the time of n
\ (6 6 notes in the time of 2
\ (7 7 notes in the time of n
\ (8 8 notes in the time of 3
\ (9 9 notes in the time of n

variable triplet_remaining
2variable triplet_modifer

: triplets_etc
  S" (" one_of if
    drop 
    S" 3" one_of if
      3 triplet_remaining !
      0,66666 triplet_modifer 2!
      drop
    then
  then 
;

: triplet_modification ( f -- f )
  triplet_remaining @ 0<> if
    -1 triplet_remaining +!
    triplet_modifer 2@ f*
  then
;

\ https://abcnotation.com/wiki/abc:standard:v2.1#duplets_triplets_quadruplets_etc
: get_note ( -- false | float-Duration float-freq true )
    new_note
    barlines 
    guitar-chords fiddle-bowing 
    triplets_etc
    accents accidental
    base-note false = if
        false exit
    then
    octave note-length
    finish_number
    triplet_modification
    note_n @ rest_note = if
        0,0
    else
        note_n @ note_to_freq
    then

    true
;

variable current_volume
2variable current_ms_per_note

: note_len>ms ( float-dur -- )
    current_ms_per_note 2@ 2swap f* f>s
;

: ABC_make_note ( float-dur float-freq -- )
    \ uses current_volume and current freq
    2dup 0,0 d<> if
        tone_on
    else
        2drop tone_off
    then
    note_len>ms  ms
    tone_off
;


\ accepts zero for the two parameters and uses defaults
: ABC_play_once ( tempo_bpm volume -- )
    0 triplet_remaining !

    \ default volume
    dup 0= if drop 248 then
    current_volume !

    \ default BPM
    dup 0= if drop 120 then
    s>f 60000,0 2swap f/ 2dup
    current_ms_per_note 2!

    begin
        get_note
    while
        \ ." dur=" f. ." freq=" f. cr
        ABC_make_note
    repeat
    tone_off
;

: ABC_test ( -- )
  \ for testing - Notice the accident holds in a bar
  \ http://www.onlinesheetmusic.com/if-i-were-a-rich-man-p110718.aspx
  \ Jetset in game tune :-)
  S" | GFGF E2C2 | z2 EF GFGF  | EFGA _BABA | G2 z6 | _A2G2 _G2F2 | _EDCD E2z2 | _EDCD E2C2 | G2 z6 |"
 
  ABC_decoder
  370 0 ABC_play_once
;
: jetset ABC_test ;


end-module

