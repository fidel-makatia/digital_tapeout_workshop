# Student Exercises

## Session 1 Exercises

### Exercise 1.1: Modify the Program ROM (Beginner)

**Goal:** Change the demo program to count from 1 to 10 instead of 1 to 5.

**File to edit:** `rtl/core/program_rom.v`

**Hints:**
- The current program subtracts 6 and checks for zero (line `rom[4]`)
- Change the subtraction value to 11 (`0x0B`) so it halts when ACC reaches 11
- Update `rom[6]` to add 11 back to restore

**Verify:** `make test_soc` — GPIO should output 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

---

### Exercise 1.2: Write a Fibonacci Program (Intermediate)

**Goal:** Output Fibonacci numbers to GPIO.

**File to edit:** `rtl/core/program_rom.v`

**Program outline:**
```
LDA #1       ; first fib number
STA 0x10     ; store as "previous"
OUT          ; output 1
LDA #1
STA 0x11     ; store as "current"
OUT          ; output 1
; loop:
LDM 0x11    ; acc = current
ADDA 0x10   ; acc = current + previous
STA 0x12    ; temp = next
LDM 0x11
STA 0x10    ; previous = current
LDM 0x12
STA 0x11    ; current = next
OUT         ; output next
JMP loop    ; repeat
```

**Verify:** GPIO outputs should be: 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233...

---

### Exercise 1.3: Add a New ALU Operation (Advanced)

**Goal:** Add a `MIN(A, B)` operation to the ALU.

**File to edit:** `rtl/core/alu.v`

**Steps:**
1. Use ALU opcode `4'hB` (unused)
2. Implement: `result = (a < b) ? a : b`
3. Add a test case to `tb/alu_tb.v`

**Verify:** `make test_alu` — your new test should pass

---

### Exercise 1.4: LED Pattern Generator (Creative)

**Goal:** Write a program that outputs a "walking LED" pattern to GPIO.

**Pattern:** `00000001 → 00000010 → 00000100 → ... → 10000000 → 00000001`

**Hint:** Use SHL instruction in a loop. When the value overflows (carry flag isn't directly testable via branch, so subtract 0 and check if the shifted result is zero), reload with 1.

**Alternative approach:** Use a lookup table stored in RAM.

---

## Session 2 Exercises

### Exercise 2.1: Analyze Gate Count

After running `make synth`, open `outputs/synth_report.txt`.

**Questions:**
1. How many total cells are in the design?
2. What percentage is the ROM vs the ALU vs the control logic?
3. If you added a multiplication instruction, how would you expect the gate count to change?

---

### Exercise 2.2: Timing Analysis

After running `make pnr`, examine the timing report.

**Questions:**
1. What is the critical path delay?
2. What is the maximum clock frequency this design could achieve?
3. Which module is on the critical path?

---

## Session 3 Exercises

### Exercise 3.1: DRC Clean

After running `make drc`, check `outputs/drc_report.txt`.

**Questions:**
1. Are there any DRC violations?
2. If yes, what type of violations are they?
3. How would you fix them?

---

### Exercise 3.2: TinyTapeout Submission (Bonus)

Visit [tinytapeout.com](https://tinytapeout.com) and follow their submission guide:
1. Fork the TinyTapeout template
2. Replace the user module with our `soc_top`
3. Map GPIO to TinyTapeout I/O pins
4. Run their GitHub Actions CI
5. Submit for the next shuttle run!

---

## Challenge Problems (Take-Home)

### Challenge A: Implement a Simple Assembler

Write a Python script that converts assembly text:
```
LDA 5
ADD 3
OUT
HLT
```
Into the hex format for `program_rom.v`:
```
rom[0] = 16'h01_05;
rom[1] = 16'h02_03;
rom[2] = 16'h0D_00;
rom[3] = 16'h0F_00;
```

### Challenge B: Add an Interrupt System

Design (on paper) how you would add a single external interrupt to this CPU. Consider:
- Where does the interrupt vector point?
- How does the CPU save/restore state?
- What new instructions are needed?

### Challenge C: Memory-Mapped I/O

Modify the GPIO module so that addresses 0xFE and 0xFF in data RAM map to GPIO input and output respectively. This way, `STA 0xFF` writes to GPIO and `LDM 0xFE` reads from GPIO, eliminating the need for dedicated IN/OUT instructions.
