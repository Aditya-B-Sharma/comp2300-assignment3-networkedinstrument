.syntax unified
.global main

.include "libcomp2300/macros.S"

@ https://cs.anu.edu.au/courses/comp2300/assignments/03-networked-instrument/

@@ In main loop, play next sample
@@ once timer is over, go to the interrupt handler (sender)
@@ interrupt handler acts as sender, make it send the changes needed

@@ To SEND DATA OUT on the GPIO pin,
@@ you write a 0 or 1 to the GPIO port’s Output Data Register (ODR). 
@@ GPIOx_ODR_set E, 12

@@ for PH1, you SEND both rising and falling,
@@ but in the receiver you only care about the rising

@@ You READ DATA IN from the GPIO pin with GPIOx_IDR_read - this will always leave the current value (0 or 1) in r0 
@@ and also set the flags appropriately, and it doesn’t change the signal on the pin.
@@ GPIOx_IDR_read H, 0
@@ receiver needs pitch_seq
@@ receiver needs interrupts for both 

@@ does your interrup handler function clear it’s pending register 
@@ before it exits? (the EXTI_PR_clear_pending macro will probably help you out here)

.type main, %function
main:
  RCC_APB2ENR_set 0

  GPIOx_clock_enable E
  GPIOx_clock_enable H

  GPIO_configure_output_pin E, 12
  GPIO_configure_output_pin E, 13

  GPIO_configure_input_pin_it H, 0
  GPIO_configure_input_pin_it H, 1 

  EXTI_set_rising_edge_trigger 0
  EXTI_set_falling_edge_trigger 0

  EXTI_set_rising_edge_trigger 1

  NVIC_set ISER 6
  NVIC_set ISER 7

  nop
  b main
.size main, .-main


.data
 pitch_seq_index:
 .word #22000, #24694, #26163, #29366, #32963, #36999, #39200, #44000