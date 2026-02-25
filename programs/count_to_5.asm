; ============================================
; Demo Program: Count 1 to 5
; ============================================
; Outputs values 1, 2, 3, 4, 5 to GPIO
; then halts.

    LDA 1       ; acc = 1
    STA 0x20    ; store in memory (scratch)
loop:
    OUT         ; output acc to GPIO
    INC         ; acc = acc + 1
    SUB 6       ; check if acc == 6
    JZ  done    ; if zero, we're done
    ADD 6       ; restore acc
    JMP loop    ; repeat
done:
    HLT         ; stop
