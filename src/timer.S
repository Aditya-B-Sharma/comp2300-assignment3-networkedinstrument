.syntax unified

.global SysTick_Handler

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

  @ you need to call this function (part of the template)
  bl HAL_IncTick

  @ any other stuff you want to put in the handler goes here

  pop {lr}
  bx lr
.size SysTick_Handler, .-SysTick_Handler
