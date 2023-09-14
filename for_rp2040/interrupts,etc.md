# Robot Interrrupts, Timers, Tasks, etc. 


ISR = Interrupt Service Routine

## Ideal Priorities

NOTE RP2040 IRQ Priorities:
 - 0 is the highest priority
 - 3 is the lowest
 - NMI is highest


Higher to lower

1. Encode change interrupts (NMI?)

2. Robot Systick (and ADC completion) - must complete before next robot systick. Robot systick should't slip from 2 ms, and generally should not be [finished this sentence].

Zeptoforth systick - Default priority 1 (could be made to 2). (Systick increments the SysTick counter and, when appropriate, schedules the PendSV)

[[NOTE: "As for moving the SysTick to priority 2, that probably wouldn't break anything, but is not ideal because it would make it impossible to make interrupts that have lower priority than SysTick but higher priority than PendSV. Note that PendSV ought to have the lowest priority of all interrupts, hence why it and only it has priority 3."]]

3. Serial Interrupts for main Forth terminal. (RP2040 UART0 RX/TX on pin GPIO0 & GPIO1).
(could be above Forth systick / Robot systick).

Zeptoforth PendSV - Default Priority 3. (PendSV is where the multitasker and interrupt bottom halves live. The PendSV can be triggered independent of the SysTick (by executing pause)).

4. Task - NINA Wifi chip - ADC read, RGB LED control, Wi-Fi interaction

5. High-level robot control task

6. Task - Buzzer frequency

7. Forth console task


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




# References
    - GPIO change interrupt https://github.com/tabemann/zeptoforth/discussions/50
    - Set interrupt priorities https://github.com/tabemann/zeptoforth/discussions/57
    - PWM discussion  https://github.com/tabemann/zeptoforth/discussions/56 

