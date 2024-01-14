\ ukmarsbot_forth
\ (c) 2022 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: loads forth files into the robot.
\ 
\ NOTE1: This file loads the files into the robot to make a complete robot.
\        The order is important.
\ 
\ NOTE2: This isn't standard Forth - include and require are used by the terminal program. 
\        Alternatively, you can do it automatically. 

#require IOBase.fth
#require ADCbase.fth
\ #require board_setup.fth
\ #require robot.fth

