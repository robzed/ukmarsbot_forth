\ ukmarsbot_forth
\ (c) 2023 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: Robot motion configuration

\ Based on ukmars mazerunner core by Peter Harrison, MIT license

\ ---------------------------------------------------
\ Dynamic performance constants
\ There is a video describing how to get these numbers and calculate the feedforward
\ constants here: https://youtu.be/BrabDeHGsa0

475,0 fconstant FWD_KM  \ mm/s/Volt
0,190 fconstant FWD_TM  \ forward time constant
775,0 fconstant ROT_KM  \ deg/s/Volt
0,210 fconstant ROT_TM  \ rotation time constant

\ Motor Feedforward
\ Speed Feedforward is used to add a drive voltage proportional to the motor speed
\ The units are Volts per mm/s and the value will be different for each
\ robot where the motor + gearbox + wheel diamter + robot weight are different
\ You can experimentally determine a suitable value by turning off the controller
\ and then commanding a set voltage to the motors. The same voltage is applied to
\ each motor. Have the robot report its speed regularly or have it measure
\ its steady state speed after a period of acceleration.
\ Do this for several applied voltages from 0.5 Volts to 5 Volts in steps of 0.5V
\ Plot a chart of steady state speed against voltage. The slope of that graph is
\ the speed feedforward, SPEED_FF.
\ Note that the line will not pass through the origin because there will be
\ some minimum voltage needed just to ovecome friction and get the wheels to turn at all.
\ That minimum voltage is the BIAS_FF. It is not dependent upon speed but is expressed
\ here as a fraction for comparison.

1,0 FWD_KM f/                fconstant SPEED_FF
FWD_TM FWD_KM f/             fconstant ACC_FF
0,121                        fconstant BIAS_FF
6,0 BIAS_FF f- SPEED_FF f/   fconstant TOP_SPEED

\ *** MOTION CONTROL CONSTANTS **********************************************//

\ forward motion controller constants
0.707  fconstant FWD_ZETA
FWD_TM fconstant FWD_TD

16,0 FWD_TM f*   FWD_KM FWD_ZETA f* FWD_ZETA f* FWD_TD f* FWD_TD f*  f/ fconstant FWD_KP
8,0 FWD_TM f* FWD_TD f- LOOP_FREQUENCY f*   FWD_KM FWD_TD f*  f/        fconstant FWD_KD

\ rotation motion controller constants
0.707  fconstant ROT_ZETA
ROT_TM fconstant ROT_TD

16,0 ROT_TM f*    ROT_KM ROT_ZETA f* ROT_ZETA f* ROT_TD f* ROT_TD f* f/ fconstant ROT_KP
8,0 ROT_TM f* ROT_TD f- LOOP_FREQUENCY F*   ROT_KM ROT_TD f*  f/        fconstant ROT_KD

\ controller constants for the steering controller
0,25 fconstant STEERING_KP
0,00 fconstant STEERING_KD
10,0 fconstant STEERING_ADJUST_LIMIT  \ deg/s


: calc_motion_config
;



