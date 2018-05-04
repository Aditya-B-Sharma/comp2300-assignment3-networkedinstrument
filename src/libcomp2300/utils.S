.syntax unified
@ --------------------- Module Interface --------------------

@ Function exports:
.global delay
.global SYSCFG_EXTIxCR_write, NVIC_EXTI_enable, NVIC_EXTI_disable
.global NVIC_IPR_set_priority, SHPR_set_priority

@ --------------------- Implementation --------------------
.include "libcomp2300/macros.S"

.type delay, %function
@ --parameters--
@ r0: delay amount
delay:
  subs r0, 1
  bmi delay_return
  b delay
delay_return:
  bx lr
.size delay, .-delay

@ Other helper functions
.type SYSCFG_EXTIxCR_write, %function
@ --parameters--
@ r0: port index (IDX_GPIOx)
@ r1: pin number
SYSCFG_EXTIxCR_write:
  push {lr}
  @ r2 = 4 * (pin // 4) + 0x8
  @ r3 = 4 * (pin mod 4)
  lsr r2, r1, 2
  lsl r2, 2
  sub r3, r1, r2
  lsl r3, 2
  add r2, 0x8

  mov r1, r0
  ldr r0, =ADR_SYSCFG
  add r0, r2
  mov r2, r3
  mov r3, 3
  bl copy_bits

  pop {lr}
  bx lr
.size SYSCFG_EXTIxCR_write, .-SYSCFG_EXTIxCR_write

.type NVIC_EXTI_enable, %function
@ --parameters--
@ r0: pin number
NVIC_EXTI_enable:
  push {lr}
  ldr r1, =OFS_NVIC_ISER0  @ offset
  add r2, r0, 6            @ shift
  cmp r0, 4
  ble NVIC_EXTI_enable_do
  mov r2, 23
  cmp r0, 9
  ble NVIC_EXTI_enable_do
  add r1, 0x4
  mov r2, 8
NVIC_EXTI_enable_do:
  ldr r0, =ADR_NVIC
  bl set_bit
  pop {lr}
  bx lr
.size NVIC_EXTI_enable, .-NVIC_EXTI_enable

.type NVIC_EXTI_disable, %function
@ --parameters--
@ r0: pin number
NVIC_EXTI_disable:
  push {lr}
  ldr r1, =OFS_NVIC_ICER0   @ offset
  add r2, r0, 6             @ shift
  cmp r0, 4
  ble NVIC_EXTI_disable_do
  mov r2, 23
  cmp r0, 9
  ble NVIC_EXTI_disable_do
  add r1, 0x4
  mov r2, 8
NVIC_EXTI_disable_do:
  ldr r0, =ADR_NVIC
  bl set_bit
  pop {lr}
  bx lr
.size NVIC_EXTI_disable, .-NVIC_EXTI_disable

.type NVIC_IPR_set_priority, %function
@ --parameters--
@ r0: position
@ r1: priority
NVIC_IPR_set_priority:
  push {lr}
  @ r2 = 4 * (pos // 4)
  @ r3 = 8 * (pos mod 4) + 4
  lsr r2, r0, 2
  lsl r2, 2
  sub r3, r0, r2
  lsl r3, 3
  add r3, 4

  ldr r0, =(ADR_NVIC + 0x300)
  add r0, r2
  mov r2, r3
  mov r3, 4
  bl copy_bits

  pop {lr}
  bx lr
.size NVIC_IPR_set_priority, .-NVIC_IPR_set_priority

.type SHPR_set_priority, %function
@ --parameters--
@ r0: position
@ r1: priority
SHPR_set_priority:
  push {lr}
  @ r2 = 4 * (pos // 4)
  @ r3 = 8 * (pos mod 4) + 4
  lsr r2, r0, 2
  lsl r2, 2
  sub r3, r0, r2
  lsl r3, 3
  add r3, 4

  ldr r0, =0xE000ED14
  add r0, r2
  mov r2, r3
  mov r3, 4
  bl copy_bits

  pop {lr}
  bx lr
.size SHPR_set_priority, .-SHPR_set_priority
