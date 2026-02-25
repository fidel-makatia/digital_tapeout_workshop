# Instruction Set Architecture (ISA) Reference

## 8-bit Accumulator Microcontroller

### Architecture Overview

```
                    ┌──────────────┐
                    │  Program ROM │
                    │  256 x 16b  │
                    └──────┬───────┘
                           │ instruction[15:0]
                    ┌──────▼───────┐
              ┌─────│  Control Unit│─────┐
              │     │   (FSM)      │     │
              │     └──────────────┘     │
              │            │             │
         ┌────▼────┐  ┌───▼────┐  ┌─────▼─────┐
         │   ALU   │  │  Data  │  │   GPIO    │
         │  8-bit  │  │  RAM   │  │  8b in/out│
         └─────────┘  │ 256x8b │  └───────────┘
                      └────────┘
```

### Registers

| Register | Width | Description |
|----------|-------|-------------|
| `ACC` | 8-bit | Accumulator — primary working register |
| `PC` | 8-bit | Program counter — addresses ROM (0x00–0xFF) |
| `ZF` | 1-bit | Zero flag — set when result is zero |
| `CF` | 1-bit | Carry flag — set on overflow/underflow |

### Memory Map

| Address Range | Size | Description |
|---------------|------|-------------|
| ROM 0x00–0xFF | 256 x 16-bit | Program memory (read-only) |
| RAM 0x00–0xFF | 256 x 8-bit | Data memory (read/write) |
| GPIO Output | via `OUT` instruction | 8-bit output port |
| GPIO Input | via `IN` instruction | 8-bit input port |

### Instruction Encoding

Each instruction is 16 bits wide:

```
 15       8  7        0
┌──────────┬──────────┐
│  OPCODE  │ OPERAND  │
│  (8 bit) │ (8 bit)  │
└──────────┴──────────┘
```

### Execution Pipeline

Every instruction takes exactly **3 clock cycles**:

```
Cycle 1: FETCH   — Read instruction from ROM[PC]
Cycle 2: DECODE  — Decode opcode, set up ALU/memory signals
Cycle 3: EXECUTE — Latch result, update PC
```

### Complete Instruction Reference

#### Data Movement

| Opcode | Mnemonic | Operand | Operation | Flags |
|--------|----------|---------|-----------|-------|
| `0x01` | `LDA imm` | immediate | `ACC ← imm` | Z, C |
| `0x09` | `LDM addr` | address | `ACC ← RAM[addr]` | Z |
| `0x08` | `STA addr` | address | `RAM[addr] ← ACC` | — |
| `0x0D` | `OUT` | — | `GPIO_OUT ← ACC` | — |
| `0x0E` | `IN` | — | `ACC ← GPIO_IN` | Z, C |

#### Arithmetic

| Opcode | Mnemonic | Operand | Operation | Flags |
|--------|----------|---------|-----------|-------|
| `0x02` | `ADD imm` | immediate | `ACC ← ACC + imm` | Z, C |
| `0x03` | `SUB imm` | immediate | `ACC ← ACC - imm` | Z, C |
| `0x12` | `INC` | — | `ACC ← ACC + 1` | Z, C |
| `0x13` | `DEC` | — | `ACC ← ACC - 1` | Z, C |
| `0x14` | `ADDA addr` | address | `ACC ← ACC + RAM[addr]` | Z, C |
| `0x15` | `SUBA addr` | address | `ACC ← ACC - RAM[addr]` | Z, C |

#### Logic

| Opcode | Mnemonic | Operand | Operation | Flags |
|--------|----------|---------|-----------|-------|
| `0x04` | `AND imm` | immediate | `ACC ← ACC & imm` | Z, C |
| `0x05` | `OR imm` | immediate | `ACC ← ACC \| imm` | Z, C |
| `0x06` | `XOR imm` | immediate | `ACC ← ACC ^ imm` | Z, C |
| `0x07` | `NOT` | — | `ACC ← ~ACC` | Z, C |
| `0x10` | `SHL` | — | `ACC ← ACC << 1` | Z, C |
| `0x11` | `SHR` | — | `ACC ← ACC >> 1` | Z, C |

#### Control Flow

| Opcode | Mnemonic | Operand | Operation | Flags |
|--------|----------|---------|-----------|-------|
| `0x00` | `NOP` | — | No operation | — |
| `0x0A` | `JMP addr` | address | `PC ← addr` | — |
| `0x0B` | `JZ addr` | address | `if (ZF) PC ← addr` | — |
| `0x0C` | `JNZ addr` | address | `if (!ZF) PC ← addr` | — |
| `0x0F` | `HLT` | — | Halt CPU | — |

### Programming Example: Fibonacci

```
Address  Hex       Assembly         Comment
------   ------    --------         -------
0x00     01 01     LDA  #1          ; a = 1
0x01     08 10     STA  0x10        ; mem[0x10] = 1 (prev)
0x02     0D 00     OUT              ; output 1
0x03     01 01     LDA  #1
0x04     08 11     STA  0x11        ; mem[0x11] = 1 (curr)
0x05     0D 00     OUT              ; output 1
0x06     09 11     LDM  0x11        ; acc = curr
0x07     14 10     ADDA 0x10        ; acc = curr + prev
0x08     0B 0E     JZ   0x0E        ; if overflow, halt
0x09     08 12     STA  0x12        ; mem[0x12] = next (temp)
0x0A     09 11     LDM  0x11
0x0B     08 10     STA  0x10        ; prev = curr
0x0C     09 12     LDM  0x12
0x0D     08 11     STA  0x11        ; curr = next
0x0E     0D 00     OUT              ; output
0x0F     0A 06     JMP  0x06        ; loop
```

Expected GPIO output: 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233 (then wraps around 8-bit)
