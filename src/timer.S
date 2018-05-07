.syntax unified
@ This module provides a choice between SysTick and TIM7.
@ Read the comments below before using.

@ --------------------- Module Interface --------------------
.global SysTick_Handler
.global tim7_init, TIM7_IRQHandler

@ --------------------- Implementation --------------------
.include "libcomp2300/macros.S"

.type SysTick_Handler, %function
@ SysTick is initialised by the audio HAL library.
@ **DO NOT configure SysTick yourself!**
@ This interrupt is triggered every 1ms (0.001s).
@ See ~/.platformio/packages/framework-stm32cube/l4/Drivers/STM32L4xx_HAL_Driver/Src/stm32l4xx_hal.c:259
@ --parameters--
@ none
SysTick_Handler:
  push {lr}
  bl HAL_IncTick  @ needs to call HAL_IncTick function

  @ Your interrupt handler code goes here

  pop {lr}
  bx lr
.size SysTick_Handler, .-SysTick_Handler


@ ------------------------ TIM7 ------------------------
@ Timer 7 features a 16-bit prescaler and a 16-bit counter.
@ The prescaler divides the main clock (which runs at 80MHz according to definition in HAL),
@ and the counter counts up according to the divided clock.
@ When the counter counts up to the reload value,
@ an update event is triggered and an interrupt is fired.

.set CK_PSC, 80000000

.type tim7_init, %function
@ tim7_init takes two parameters, clock divisor and count (in each case, only the lower 16-bits will be used)
@
@ the clock divisor determines how many CPU cycles per TIM7 tick
@ the count determines how many TIM7 ticks between the TIM7 interrupts firing
@
@ Remember that in the assignment template, the main clock is at 80MHz
@ so, for example, clock divisor = 10000 and count = 8000 will give a 1Hz interrupt
@
@ --parameters--
@ r0: clock divisor (prescaler + 1)
@ r1: count
tim7_init:
  push {r4-r5, lr}
  mov r4, r0
  mov r5, r1

  @ enable peripheral clock
  @ RCC_APB1ENR_set 5
  ldr r0, =ADR_RCC
  ldr r1, =OFS_RCC_APB1ENR
  ldr r2, =5
  bl set_bit

  @ Set prescaler
  @ the counter clock frequency f(CK_CNT) = f(CK_PSC) / (prescaler + 1)
  @ since clock divisor = prescaler + 1,
  @ subtract 1 here to get the prescaler
  @ See Section 29.4.7
  ldr r0, =ADR_TIM7
  ldr r1, =OFS_TIMx_PSC
  sub r4, 1
  strh r4, [r0, r1]

  @ set counter reload value (Section 29.4.8)
  ldr r0, =ADR_TIM7
  ldr r1, =OFS_TIMx_ARR
  strh r5, [r0, r1]

  @ enable timer 7  (Section 29.4.1s)
  ldr r0, =ADR_TIM7
  ldr r1, =OFS_TIMx_CR1
  mov r2, 0
  bl set_bit

  @ enable TIM7 DMA/interrupt (Section 29.4.3)
  ldr r0, =ADR_TIM7
  ldr r1, =OFS_TIMx_DIER
  mov r2, 0
  bl set_bit

  @ enable TIM7 interrupt in NVIC
  NVIC_set ISER 55  @ TIM7 is at position 55

  @ set debug freeze (Section 44.16.4)
  ldr r0, =ADR_DBGMCU_APB1FZR1
  mov r1, 0
  mov r2, 5
  bl set_bit

  @ NOTE: you MAY want to configure the priority of TIM7.
  @ put your code here if that's the case

  pop {r4-r5, lr}
  bx lr
.size tim7_init, .-tim7_init

.type TIM7_IRQHandler, %function
@ --parameters--
@ none
TIM7_IRQHandler:
  push {lr}

  @ Your interrupt handler code goes here

  @ Clear interrupt (Section 29.4.4)
  ldr r0, =ADR_TIM7
  ldr r1, =OFS_TIMx_SR
  mov r2, 0
  bl clear_bit

  pop {lr}
  bx lr
.size TIM7_IRQHandler, .-TIM7_IRQHandler
