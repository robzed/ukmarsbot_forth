\ ukmarsbot_forth
\ (c) 2023 Rob Probin 
\ MIT License, see LICENSE file
\ 
\ BRIEF: Robot Motor Control for RP2040 on Zeptoforth

\ *** Descriptions from micromouse core ***

\ The Motors class is provided with two main control signals - the forward
\ and rotary speeds. A third input come from the steering correction mechanism
\ used normally when the robot is tracking a wall or line. That input could also
\ come from a trajectory tracker or a target seeker.
\
\ UKMARSBOT uses DC motors and, to get best performance with least user effort,
\ a combination of feedforward and feedbackcontrollers is used. While this can
\ seem complex, the user need not be aware of all the details so long as the
\ appropriate system characterisation is done to provide suitable values for the
\ various system constants.
\
\ Under the hood, there are a pair of position controllers which have their set
\ points continuously updated by the desired speeds. Odometry provides feedback
\ for these controllers. greater reliability and precision would be possible if
\ the odometry had better resolution and if an IMU were available. But, you can
\ get remarkably good results with the limited resources available.


variable motor_controller_enabled
variable motor_feedforward_enabled

fvariable old_fwd_error
fvariable old_rot_error
fvariable fwd_error
fvariable rot_error
fvariable omega
fvariable velocity

\ used for logging
fvariable g_right_motor_volts
fvariable f_left_motor_volts

: reset_motor_controllers
    0 fwd_error !
    0 rot_error !
    0 old_fwd_error !
    0 old_rot_error !
;


\ At each iteration of the main control loop we need to calculate
\ now outputs form the two position controllers - one for forward
\ motion, one for rotation.
\
\ The current error increases by an amount determined by the speed
\ and the control loop interval.
\
\ It is then decreased by the amount the robot has actually moved
\ in the previous loop interval.
\
\ These changes are both done in the first line.
\
\ After that we have a simple PD contoller.
\
\ NOTE: the D-term constant is premultiplied in the config by the
\ loop frequency to save a little time.
\
: position_controller ( -- f )
    velocity f@ LOOP_INTERVAL f* ( required-increment-this-step )
    robot-fwd-change@ f- fwd_error f@ f+ fwd_error f!

    fwd_error f@ fdup old_fwd_error f@ f- ( -- fwd-error error-diff )
                 fdup old_fwd_error f!

    \ PD controller:
    FWD_KP f* fswap ( error-diff fwd_error -- proportional_term error-diff )
    FWD_KD f* 
    f+ 
;


\ The rotation controller is exactly like the forward controller
\ except that there is an additional error term from the steering.
\ All steering correction is done by treating the error term as an
\ angular velocity. Depending on your method of analysis, you might
\ also try feeding the steering corection back as an angular
\ acceleration.
\
\ If you have a gyro, you can use the output from that instead of
\ the encoders.
\
\ A separate controller calculates the steering adjustment term.
\
: angle_controller ( steering_adjustment -- f )
    omega f@ LOOP_INTERVAL f* ( required-increment-this-step )
    robot-rot-change@ f- rot_error f@ f+
        f+ \ add in steering 
        rot_error f!

    rot_error f@ fdup old_rot_error f@ f- ( -- rot-error error-diff )
        fdup old_rot_error f!

    \ PD controller
    ROT_KP f* fswap  ( error-diff rot-error -- proportional-term error-diff )
    ROT_KD f*
    f+
;


\ Feed forward attempts to work out what voltage the motors would need
\ to run at the current speed and acceleration.
\
\ Without this, the controller has a lot of work to do and will be
\ much harder to tune for good performance.
\
\ The drive train is not symmetric and there is significant stiction.
\ If used with PID, a simpler, single value will be sufficient.
\

variable FF_left_oldSpeed

: leftFeedForward ( f.speed -- f )
    fdup SPEED_FF f* BIAS_FF f+ ( speed -- speed leftFF)
    fswap fdup FF_left_oldSpeed f@ f- LOOP_FREQUENCY f* ( speed leftFF -- leftFF speed acc )
    fswap FF_left_oldSpeed f! \ store this speed for next tick time
    ACC_FF f* ( leftFF acc -- leftFF accFF )
    f+ 
;

variable FF_right_oldSpeed

: rightFeedForward ( f.speed -- f )
    fdup SPEED_FF f* BIAS_FF f+ ( speed -- speed rightFF)
    fswap fdup FF_right_oldSpeed f@ f- LOOP_FREQUENCY f* ( speed rightFF -- rightFF speed acc )
    fswap FF_right_oldSpeed f! \ store this speed for next tick time
    ACC_FF f* ( rightFF acc -- rightFF accFF )
    f+ 
;

2,0 PI f* 360,0 f/ fconstant RADIANS_PER_DEGREE


: calc_feedforward_speeds ( -- f.left_ff f.right_ff )
    omega MOUSE_RADIUS f* RADIANS_PER_DEGREE f* ( -- tangent_speed )
    fdup
    velocity f@ fswap f- ( -- tangent_speed left_speed ) 
    fswap velocity f@ f+ ( -- left_speed right_speed )
    fswap leftFeedForward ( left_speed right_speed -- right_speed left-ff )
    fswap rightFeedForward ( -- left-ff right-ff )
;


\ Calculate the outputs of the feedback and feedforward controllers
\ for both forward and rotation, and combine them to obtain drive
\ voltages for the left and right motors.
\
: update_controllers ( velocity omega steering_adjustment -- )
    fswap omega f!
    fswap velocity f!

    angle_controller    ( steering_adjustment -- rot_output )
    position_controller ( -- pos_output )

    \ convert the rotation and position into left and right components

    ( f.rot_output f.pos_output )
    f2dup
    fswap f-    ( rot pos rot pos -- rot pos left_output )
    f-rot f+    ( rot pos left_out -- f.left_output f.right_output)

    calc_feedforward_speeds ( [..] -- [..] f.left_ff f.right_ff )

    ( f.left_output f.right_output f.left_ff f.right_ff )

    motor_feedforward_enabled @ if
      frot f+ ( left_out left_ff new_r_out )
      f-rot f+ ( new_r_out new_l_out )
      fswap
    else
        fdrop fdrop
    then

    ( left right )
    motor_controller_enabled @ if
      ( right_output ) set_right_motor_volts
      ( left_output ) set_left_motor_volts
    then
;




: set_speeds ( velocity omega  -- )
    di
        omega f!
        velocity f!
    ei
;


\ should be below battery voltage, otherwise you won't get requested drive!
6,0 constant MAX_MOTOR_VOLTS

: constain_voltage ( f.volts -- f.volts )
  MAX_MOTOR_VOLTS fmin MAX_MOTOR_VOLTS fnegate fmax 
;

: pwm_compensated ( desired_v -- pwm-value )
    f_battery_volts f@ f/ MOTOR_MAX_PWM f* f>s
;

: left_motor_volts! ( f.volts -- ) 
  constain_voltage
  dup g_left_motor_volts !
  pwm_compensated
  left_motor_pwm!
;

: right_motor_volts! (f.volts -- )
  constain_voltage
  dup g_right_motor_volts !
  pwm_compensated
  right_motor_pwm!
;

: stop_motors
    0 left_motor_volts!
    0 right_motor_volts!
;

: setup_motors
    reset_motor_controllers
    0 FF_left_oldSpeed !
    0 FF_right_oldSpeed !
    0 0 set_speeds

    false motor_controller_enabled !
    true motor_feedforward_enabled !

    start_motor_pwm
    stop_motors    
;

