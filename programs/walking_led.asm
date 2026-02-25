; ============================================
; Walking LED Pattern
; ============================================
; Shifts a single lit LED across 8 positions:
; 00000001 -> 00000010 -> ... -> 10000000
; Then wraps back to 00000001.
; Runs forever (no HLT).

    LDA 1           ; start with bit 0

shift_loop:
    OUT             ; output current pattern
    SHL             ; shift left

    ; Check if we shifted past bit 7 (result = 0)
    SUB 0           ; compare with zero (doesn't change acc, but sets ZF)
    JZ  reset       ; if zero, wrap around
    JMP shift_loop  ; otherwise keep shifting

reset:
    LDA 1           ; reload bit 0
    JMP shift_loop  ; restart pattern
