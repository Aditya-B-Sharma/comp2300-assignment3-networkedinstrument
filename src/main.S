.syntax unified
.global main
.global EXTI0_IRQHandler
.global EXTI1_IRQHandler
.global TIM7_IRQHandler

.include "libcomp2300/macros.S"

.macro toggles amount

  mov r12, \amount 

  iterate\@:
  GPIOx_ODR_toggle E, 13 
  subs r12, 1
  beq end\@

.endm

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


  bl init

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


  mov r0, 10000
  mov r1, 2000
  bl tim7_init

  b receiver



.size main, .-main
receiver:                                      @ Continually check if port is triggered
    GPIOx_IDR_read H 0
    beq receiver
    bl wave_play_next_sample                     @ If triggered, play sound
    b receiver





.type EXTI0_IRQHandler, %function

EXTI0_IRQHandler:
  push {lr}
  GPIOx_IDR_read H 0
  beq next
  bne playsound

  
  playsound:
    bl wave_play_next_sample

  next:


  EXTI_PR_clear_pending 0
  pop {lr}

  bx lr
  .size EXTI0_IRQHandler, .-EXTI0_IRQHandler  




.type EXTI1_IRQHandler, %function
EXTI1_IRQHandler:
push {lr}

@@load index
  ldr r11, =index
  ldr r12, [r11]

  @@ multiply 4 by index value to get offset
  mov r10, 4
  mul r10, r12, r10 

  @@ load the number from pitch_seq given the offset into r0
  @@ and change the wave

  ldr r8, =pitch_seq
  ldr r0, [r8, r10]
  mov r1, 0b1000001100000000

  
  bl wave_change

  @@ see if we've maxed index yet
  @@ if so, reset, otherwise, add 1 to it
  cmp r12, 7
  bne continue

  mov r12, 0
  str r12, [r11]
  b clear_interrupt

  continue:
    add r12, 1
    str r12, [r11]
    

  clear_interrupt:

  EXTI_PR_clear_pending 1

  pop {lr}

  bx lr
  .size EXTI1_IRQHandler, .-EXTI1_IRQHandler  
 





.type TIM7_IRQHandler, %function
@ --parameters--
@ none
TIM7_IRQHandler:
  
  push {lr}

  GPIOx_ODR_toggle E, 12

  ldr r11, =offset
  ldr r10, [r11] 

  add r5, r10, 4

  str r5, [r11]
 
  ldr r9, =sender_indices
  ldr r8, [r9]

  ldr r7, [r9, r10]

  ldr r6, [r9, r5]

  cmp r7, 1
  beq checkifnextiszero
  bne dontcheck

  checkifnextiszero:
    cmp r6, 0
    beq resetoffset
    bne dontcheck

  resetoffset:
    mov r4, 0
    str r4, [r11]

  dontcheck:
    sub r4, r6, r7
    cmp r4, 0
    beq end_tim7
    cmp r4, 1
    beq sendonesignal
    bne sendonesignal


  sendonesignal:
   
    GPIOx_ODR_set E, 13
    GPIOx_ODR_clear E, 13
    b end_tim7

  sendmultiple:
    mov r11, #6

  end_tim7:

  @ Clear interrupt (Section 29.4.4)
    ldr r0, =ADR_TIM7
    ldr r1, =OFS_TIMx_SR
    mov r2, 0
    bl clear_bit
    pop {lr}
    bx lr
.size TIM7_IRQHandler, .-TIM7_IRQHandler  


.data
 pitch_seq:
 .word 22000, 24694, 26163, 29366, 32963, 36999, 39200, 44000
 on_off_check:
 .word 1
 index:
 .word 0
 offset:
 .word 0
 sender_indices:
 .word 0, 1, 2, 3, 4, 5, 6, 7, 7, 6, 5, 4, 3, 2, 1, 0