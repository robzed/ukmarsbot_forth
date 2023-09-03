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

    variable song_str
    variable song_len
    variable note_n
    variable note_modifier
    variable note_len
    variable note_accidentals

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

\ local note_table = { 
\     C = 0, -- middle C
\     D = 2,
\     E = 4,
\     F = 5,
\    G = 7,
\    A = 9,
\    B = 11,
\
\    c = 12,
\    d = 14,
\    e = 16,
\    f = 17,
\    g = 19,
\    a = 21,
\    b = 23,
\ }

: do_note (  c -- )
\    local note = note_table[c]
\    if note then
\        local mod = music._flags.current_note_modifier
\        if mod then
\            music._flags.current_note_modifier = nil
\            music._flags.note_accidentals[note] = mod
\        else
\            mod = music._flags.note_accidentals[note]
\            if not mod then
\                mod = 0
\            end
\        end
\        note = note + mod
\        table.insert(music.songnote, note)
\        table.insert(music.songlen, 1)
\    end
;

: do_down_1_octive ( -- )
    -12 note_n +!
;

: do_up_2_octives ( -- )
    24 note_n +!
;

: do_sharp ( -- )
    1 note_modifier +!
;

: do_natural ( -- )
    0 note_modifier !
;

: do_flat ( -- )
    -1 note_modifier +!
;

: do_rest ( -- )
        \ table.insert(music.songnote, nil)
        \ table.insert(music.songlen, 1)
;

: do_number ( c -- )
    \ if c == "/" then
    \     m._flags.fraction = true
    \ elseif m._flags.in_number then
    \     m._flags.in_number = m._flags.in_number * 10 + string.byte(c) - string.byte("0")
    \ else
    \    m._flags.in_number = string.byte(c) - string.byte("0")
    \ end
;

: do_barline ( c -- )
    \ applies to this measure(=bar) only
    0 note_accidentals !
;


0 value decode_char_table_addr \ represents from 32 to 127, i.e. 96 characters
: >decode_char_table ( char xt -- )
    swap BL - CELLS decode_char_table_addr !
;
: create_decode_char_table
    [CHAR] C do_note >decode_char_table
    [CHAR] D do_note >decode_char_table
    [CHAR] E do_note >decode_char_table
    [CHAR] F do_note >decode_char_table
    [CHAR] G do_note >decode_char_table
    [CHAR] A do_note >decode_char_table
    [CHAR] B do_note >decode_char_table
    [CHAR] c do_note >decode_char_table
    [CHAR] d do_note >decode_char_table
    [CHAR] e do_note >decode_char_table
    [CHAR] f do_note >decode_char_table
    [CHAR] g do_note >decode_char_table
    [CHAR] a do_note >decode_char_table
    [CHAR] b do_note >decode_char_table
    [CHAR] , do_down_1_octive >decode_char_table
    [CHAR] ' do_up_2_octives >decode_char_table
    [CHAR] ^ do_sharp >decode_char_table
    [CHAR] = do_natural >decode_char_table
    [CHAR] _ do_flat >decode_char_table
    [CHAR] z do_rest >decode_char_table
    [CHAR] 0 do_number >decode_char_table
    [CHAR] 1 do_number >decode_char_table
    [CHAR] 2 do_number >decode_char_table
    [CHAR] 3 do_number >decode_char_table
    [CHAR] 4 do_number >decode_char_table
    [CHAR] 5 do_number >decode_char_table
    [CHAR] 6 do_number >decode_char_table
    [CHAR] 7 do_number >decode_char_table
    [CHAR] 8 do_number >decode_char_table
    [CHAR] 9 do_number >decode_char_table
    [CHAR] / do_number >decode_char_table
\     BL  do_note >decode_char_table
    [CHAR] | do_barline >decode_char_table
;
: init_decode_char_table
\     decode_char_table_addr 0= if
\         \ allocate some buffer
\        xxx to decode_char_table_addr
\         decode_char_table_addr 128 BL - cells 0 fill
\        create_decode_char_table
\     then
;
: decode_char ( c -- xt )
    CELLS decode_char_table_addr + @
;


: finish_number ( -- )
\    local len = #m.songlen
\    if len == 0 then    -- mistake in notaton
\        return
\    end
\    local num = m._flags.in_number
\    if num then
\        if m._flags.fraction then
\            num = 1 / num
\        end
\        m.songlen[len] = num
\    elseif m._flags.fraction then
\        m.songlen[len] = 0.5   -- same as /2
\    end
\    
\    m._flags.fraction = nil
\    m._flags.in_number = nil
;


: ABC_decoder ( music_string music_len -- ) 
    song_len !
    song_str !
    0 note_modifier !
    1 note_len !
    0 note_n !
    0 note_accidentals !

    song_len @ 0 do
        song_str c@ dup decode_char
        dup if
            dup do_number <> if
                finish_number
            then
            execute ( c xt -- )
        else
            2drop \ otherwise ignore
        then
        1+ song_str +!
    loop

    finish_number
;

: ABC_next ( -- c | -1 )
    \ return 0 if no more
    song_len @ 0= if 
        -1
    else 
        -1 song_len +!
        song_str C@
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
    again
    nip nip false
;

: ABC_back_one
    1 song_len +!
    -1 song_str +!
;


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
: base-note
    \ CDEFGABcdefgab 
    \ but also rest
    \ z
    begin
        S" CDEFGABcdefgabz" one_of
    while
        dup [CHAR] z = if
            drop do_rest 
        else
            do_note
        then
    repeat
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
    \ don't have an effect on the music
    one_of S" |" if drop then
;


: get_note ( -- false | nDuration Ffreq true )
    barlines 
    guitar-chords fiddle-bowing accents accidental base-note octave note-length
    finish_number
;


: ABC_test ( -- )
  \ for testing - Notice the accident holds in a bar
  \ http://www.onlinesheetmusic.com/if-i-were-a-rich-man-p110718.aspx
  \ Jetset in game tune :-)
  S" | GFGF E2C2 | z2 EF GFGF  | EFGA _BABA | G2 z6 | _A2G2 _G2F2 | _EDCD E2z2 | _EDCD E2C2 | G2 z6 |"
 
  ABC_decoder
  begin
    dup @ 0<>
  while
    dup @
    CELL+
  repeat
;


end-module

