.syntax unified
.global main

.include "libcomp2300/macros.S"

@ https://cs.anu.edu.au/courses/comp2300/assignments/03-networked-instrument/

.type main, %function
main:
  nop
  b main
.size main, .-main
