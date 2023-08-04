# Robot Interrrupts, Timers, Tasks, etc. 


ISR = Interrupt Service Routine

## Ideal Priorities

Higher to lower

1. Encode change interrupts

2. Robot Systick (and ADC completion) - must complete before next robot systick. Robot systick should't slip from 2 ms, and generally should not be 

3. Serial Interrupts for main Forth terminal. (RP2040 UART0 RX/TX on pin GPIO0 & GPIO1).
(could be above Forth systick / Robot systick.

4. High-level robot control task

5. Forth console task


We avoid the USB version of Zeptoforth so we don't need to worry about this. 


## Encoder Left Input Change ISR

This can occur more than 10000 times per second.
(e.g. 6 counts per millimeter at 2m/s is 120000.)


## Encoder Right Input Change ISR 

This can occur more than 10000 times per second.
(e.g. 6 counts per millimeter at 2m/s is 120000.)


## GPIO State change ISR

Calls Interrupt service routine for left and right encoder ISRs

Potentially this can occur more than 20000 times per second.

We don't want to lose interrupts from this routine.



## Encoder Update - Timer periodic

called from robot systick. Calculates the robot movement based on encoders.


## Robot Systick

Called at 500 Hz (specifically `LOOP_FREQ`).

Other timer periodic routines.

Cannot block the encoder interrupts ISRs!



## ADC completition ISR

Called when the ADC result is ready, and also the state machine to scan all the result.

Initial ADC is kicked off at the end of the robot systick routine.



## High-Level Robot Control Task

This does the overrall maze control. 

Could be done by the main task, as long as we also process commands. e.g. On Flashforth we can use either tasks or waiting for keys)




# Non-Robot Interrutps, timers, tasks, etc.

## Zeptoforth on the RP2040

Serial
Main Task - used for Forth Interpreter


## Flashforth on the dsPIC33




# Peripheral users

## RP2040 

Motor control - PWM. This does not use CPU resources, but instead the on-chip PWM controllers???

## dsPIC33




