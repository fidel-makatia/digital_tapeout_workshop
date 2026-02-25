; ============================================
; Fibonacci Sequence Generator
; ============================================
; Outputs Fibonacci numbers to GPIO:
; 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233
; Halts when overflow to zero occurs.
;
; Memory map:
;   0x10 = previous value
;   0x11 = current value
;   0x12 = temp (next value)

    ; Initialize first two Fibonacci numbers
    LDA 1
    STA 0x10        ; prev = 1
    OUT             ; output 1
    LDA 1
    STA 0x11        ; curr = 1
    OUT             ; output 1

fib_loop:
    LDM 0x11        ; acc = curr
    ADDA 0x10       ; acc = curr + prev
    JZ  halt        ; if wrapped to zero, stop
    STA 0x12        ; temp = next

    LDM 0x11
    STA 0x10        ; prev = curr

    LDM 0x12
    STA 0x11        ; curr = next
    OUT             ; output next value

    JMP fib_loop    ; repeat

halt:
    HLT
