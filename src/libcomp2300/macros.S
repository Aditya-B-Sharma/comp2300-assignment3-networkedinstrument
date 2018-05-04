.syntax unified

@ These macros are defined to be simple wrappers for function calls.
@ to use them, add
@   .include "lib/comp2300/macro.S"
@
@ These macros uses definitions in utils.S, bitops.S and symbols.S

@ macro for modulo operation
@ Rd, Rn, Rm must be different!
.macro mod Rd Rn Rm
  sdiv \Rd, \Rn, \Rm
  mul \Rd, \Rm
  rsb \Rd, \Rn
.endm

@ Generic RCC AxB2ENR macros
.macro RCC_AxB2ENR_write HorP position value
    ldr r0, =ADR_RCC
    ldr r1, =OFS_RCC_A\HorP\()B2ENR
    ldr r2, =\position
    ldr r3, =\value
    bl write_bit
.endm

.macro RCC_AxB2ENR_set HorP position
    ldr r0, =ADR_RCC
    ldr r1, =OFS_RCC_A\HorP\()B2ENR
    ldr r2, =\position
    bl set_bit
.endm

.macro RCC_AxB2ENR_clear HorP position
    ldr r0, =ADR_RCC
    ldr r1, =OFS_RCC_A\HorP\()B2ENR
    ldr r2, =\position
    bl clear_bit
.endm

@ GPIO macros
.macro GPIOx_clock_enable port
    RCC_AxB2ENR_set H IDX_GPIO\port
.endm

.macro GPIOx_MODER_write port pin mode
    ldr r0, =(ADR_GPIO\port + 0x0)
    ldr r1, =\mode
    ldr r2, =(\pin << 1)
    ldr r3, =2
    bl copy_bits
.endm

.macro GPIOx_PUPDR_write port pin mode
    ldr r0, =(ADR_GPIO\port + 0xC)
    ldr r1, =\mode
    ldr r2, =(\pin << 1)
    ldr r3, =2
    bl copy_bits
.endm

.macro GPIOx_ODR_write port pin data
    ldr r0, =ADR_GPIO\port
    ldr r1, =OFS_GPIOx_ODR
    ldr r2, =\pin
    ldr r3, =\data
    bl write_bit
.endm

.macro GPIOx_ODR_set port pin
    ldr r0, =ADR_GPIO\port
    ldr r1, =OFS_GPIOx_ODR
    ldr r2, =\pin
    bl set_bit
.endm

.macro GPIOx_ODR_clear port pin
    ldr r0, =ADR_GPIO\port
    ldr r1, =OFS_GPIOx_ODR
    ldr r2, =\pin
    bl clear_bit
.endm

.macro GPIOx_ODR_toggle port pin
    ldr r0, =ADR_GPIO\port
    ldr r1, =OFS_GPIOx_ODR
    ldr r2, =\pin
    bl toggle_bit
.endm

.macro GPIOx_IDR_read port pin
    ldr r0, =ADR_GPIO\port
    ldr r1, =OFS_GPIOx_IDR
    ldr r2, =\pin
    bl read_bit
.endm

@ ICSR
.macro ICSR_set pos
    ldr r0, =ADR_SCB_ICSR
    mov r1, 0
    ldr r2, =\pos
    bl set_bit
.endm

.macro ICSR_clear pos
    ldr r0, =ADR_SCB_ICSR
    mov r1, 0
    ldr r2, =\pos
    bl clear_bit
.endm

.macro SYSCFG_EXTIxCR_write port pin
    ldr r0, =IDX_GPIO\port
    ldr r1, =\pin
    bl SYSCFG_EXTIxCR_write
.endm

@ Interrupt related

@ EXTI

@ enable interrupt in EXTI interrupt mask register
.macro EXTI_IMR_enable number
    ldr r0, =ADR_EXTI
    mov r1, 0
    ldr r2, =\number
    bl set_bit
.endm

.macro EXTI_IMR_disable number
    ldr r0, =ADR_EXTI
    mov r1, 0
    ldr r2, =\number
    bl clear_bit
.endm

.macro EXTI_set_rising_edge_trigger pin
    ldr r0, =ADR_EXTI
    mov r1, 0x8
    ldr r2, =\pin
    bl set_bit
.endm

.macro EXTI_set_falling_edge_trigger pin
    ldr r0, =ADR_EXTI
    mov r1, 0xC
    ldr r2, =\pin
    bl set_bit
.endm

@ to see if an interrupt has been triggered
.macro EXTI_PR_check_pending pin
    ldr r0, =ADR_EXTI
    ldr r1, =0x14
    ldr r2, =\pin
    bl read_bit
.endm

@ to trigger a software interrupt
.macro EXTI_PR_set_pending pin
    ldr r0, =ADR_EXTI
    ldr r1, =0x10
    ldr r2, =\pin
    bl set_bit
.endm

@ to clear an already-triggered interrupt
@ (note: to *clear* a "pending" interrupt,
@  you need to *set* the bit in EXTI_PR1)
.macro EXTI_PR_clear_pending pin
    ldr r0, =ADR_EXTI
    ldr r1, =0x14
    ldr r2, =\pin
    bl set_bit
.endm

@ NVIC

.macro NVIC_read register position
    ldr r0, =ADR_NVIC
    ldr r1, =(OFS_NVIC_\register\()0)
    ldr r2, =(4 * (\position / 32))
    add r1, r2
    ldr r2, =(\position % 32)
    bl read_bit
.endm

.macro NVIC_set register position
    ldr r0, =ADR_NVIC
    ldr r1, =OFS_NVIC_\register\()0
    ldr r2, =(4 * (\position / 32))
    add r1, r2
    ldr r2, =(\position % 32)
    bl set_bit
.endm

.macro NVIC_EXTI_enable pin
    mov r0, \pin
    bl NVIC_EXTI_enable
.endm

.macro NVIC_EXTI_disable pin
    mov r0, \pin
    bl NVIC_EXTI_disable
.endm

@ set NVIC interrupt priority
.macro NVIC_IPR_set_priority position priority
    ldr r0, =\position
    ldr r0, =\priority
    bl NVIC_IPR_set_priority
.endm

@ set system handler priorities (e.g. SysTick, PendSV, SVCall)
.macro SHPR_set_priority position priority
    ldr r0, =\position
    ldr r0, =\priority
    bl SHPR_set_priority
.endm

@ Other high level macros

@ high-level helper macros

.macro declare_output_pin port pin
  GPIOx_MODER_write \port, \pin, 0b01
.endm

.macro declare_input_pin port pin
  GPIOx_MODER_write \port, \pin, 0b00
  GPIOx_PUPDR_write \port, \pin, 0b10
.endm

@ this one also triggers the interrupts
.macro declare_input_pin_it port pin
  declare_input_pin \port, \pin
  SYSCFG_EXTIxCR_write \port, \pin @ set port as source for this interrupt
  EXTI_IMR_enable \pin
.endm
