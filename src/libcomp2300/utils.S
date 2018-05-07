.syntax unified
@ --------------------- Module Interface --------------------

.syntax unified

@ --------------------- Module Interface --------------------
@ Function exports:
.global delay

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
