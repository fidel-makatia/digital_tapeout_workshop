# 🔬 Digital IC Tapeout Workshop

## 8-bit Accumulator Microcontroller → SKY130 Silicon

A complete 3-session workshop that takes participants from RTL to GDS using **100% open-source tools**. Students modify a working 8-bit CPU, simulate it, synthesize it, and produce a chip layout ready for fabrication.

> *"You are not building a product CPU. You are learning how real chips become silicon."*

---

## 🎯 What You'll Build

An 8-bit accumulator-based microcontroller with:
- **21 instructions** (arithmetic, logic, memory, branching, I/O)
- **256 bytes** of data RAM
- **256 x 16-bit** instruction ROM (hard-coded program)
- **8-bit GPIO** (input + output)
- **3-stage FSM** pipeline (Fetch → Decode → Execute)
- Target: **SKY130 130nm CMOS**, ≤ 5 MHz clock

---

## 📁 Repository Structure

```
digital_tapeout_workshop/
├── rtl/
│   ├── core/
│   │   ├── alu.v              ← ALU (STUDENT-MODIFIABLE)
│   │   ├── regfile.v          ← Data RAM (FROZEN)
│   │   ├── control.v          ← CPU FSM (FROZEN)
│   │   └── program_rom.v      ← Program ROM (STUDENT-MODIFIABLE)
│   ├── soc_top.v              ← Top-level SoC (FROZEN)
│   └── gpio.v                 ← GPIO (STUDENT-MODIFIABLE)
├── tb/
│   ├── alu_tb.v               ← ALU unit testbench
│   ├── gpio_tb.v              ← GPIO unit testbench
│   └── soc_tb.v               ← Full system integration testbench
├── constraints/
│   └── sky130.sdc             ← Timing constraints
├── flow/
│   ├── synth.tcl              ← Yosys synthesis script
│   ├── floorplan.tcl          ← OpenROAD floorplan
│   ├── pnr.tcl                ← OpenROAD place & route
│   ├── gds_export.tcl         ← Magic GDS export
│   ├── drc.tcl                ← Magic DRC check
│   └── lvs.tcl                ← netgen LVS check
├── docs/
│   ├── STUDENT_GUIDE.md       ← Step-by-step student instructions
│   ├── ISA_REFERENCE.md       ← Complete instruction set reference
│   └── EXERCISES.md           ← Student exercises
├── outputs/                   ← Generated files go here
├── Makefile                   ← Master build system
└── README.md                  ← You are here
```

---

## ⚡ Quick Start (Simulation Only)

You only need **Icarus Verilog** to run all simulations. No PDK required.

### Install Icarus Verilog
```bash
# Ubuntu/Debian
sudo apt install iverilog gtkwave

# macOS
brew install icarus-verilog gtkwave

# Verify
iverilog -V
```

### Run All Tests
```bash
git clone https://github.com/YOUR_USERNAME/digital_tapeout_workshop.git
cd digital_tapeout_workshop
make sim
```

### Expected Output
```
========== ALU Unit Test ==========
  [PASS] Test 1: op=0 a=42 b=00 -> result=42 z=0 c=0
  [PASS] Test 2: op=0 a=00 b=ff -> result=00 z=1 c=0
  ...
  Results: 24 PASSED, 0 FAILED out of 24
  >>> ALL TESTS PASSED <<<

========== SoC Integration Test ==========
  [INFO] Reset released at time 510000
  [GPIO] Cycle 10: gpio_out changed to 0x01 (1)
  [GPIO] Cycle 28: gpio_out changed to 0x02 (2)
  [GPIO] Cycle 46: gpio_out changed to 0x03 (3)
  [GPIO] Cycle 64: gpio_out changed to 0x04 (4)
  [GPIO] Cycle 82: gpio_out changed to 0x05 (5)
  [INFO] CPU halted at cycle 88
  ...
  >>> ALL TESTS PASSED - READY FOR SYNTHESIS <<<
```

### View Waveforms
```bash
make wave       # Opens SoC waveforms in GTKWave
make wave_alu   # Opens ALU waveforms
```

---

## 🏗️ Full Backend Flow (Requires SKY130 PDK)

### Install All Tools

```bash
# 1. Install Yosys
sudo apt install yosys

# 2. Install OpenROAD
# See: https://github.com/The-OpenROAD-Project/OpenROAD/releases

# 3. Install Magic
sudo apt install magic

# 4. Install netgen
sudo apt install netgen-lvs

# 5. Install SKY130 PDK
git clone https://github.com/google/skywater-pdk.git /opt/skywater-pdk
export PDK_ROOT=/opt/skywater-pdk

# Verify all tools
make check_tools
```

### Run Complete RTL-to-GDS Flow

```bash
make all
```

This runs: **Simulation → Synthesis → Floorplan → Place & Route → GDS Export → DRC → LVS**

### Run Individual Steps

```bash
make sim          # Simulate and verify
make synth        # Synthesize to SKY130 gates
make floorplan    # Create chip floorplan
make pnr          # Place and route
make gds          # Export final GDS
make drc          # Design rule check
make lvs          # Layout vs schematic
```

---

## 🎓 3-Session Workshop Plan

### Session 1: RTL Understanding & Simulation (2 hours)
**Tools needed:** Icarus Verilog, GTKWave

1. Architecture walkthrough (30 min)
2. ISA and instruction execution demo (20 min)
3. **Hands-on:** Modify ALU or program ROM (40 min)
4. Run simulations, view waveforms (20 min)
5. Wrap-up and Q&A (10 min)

**Deliverable:** All testbenches passing

### Session 2: Synthesis & Place-and-Route (2 hours)
**Tools needed:** Yosys, OpenROAD

1. Synthesis concepts (20 min)
2. Run `make synth`, inspect gate count (20 min)
3. Floorplanning walkthrough (20 min)
4. Run `make floorplan` and `make pnr` (30 min)
5. Inspect timing reports (20 min)
6. Wrap-up (10 min)

**Deliverable:** Routed design

### Session 3: Verification & Tapeout (2 hours)
**Tools needed:** Magic, netgen

1. DRC/LVS concepts (20 min)
2. Run `make gds`, `make drc`, `make lvs` (30 min)
3. Visual layout inspection in Magic (20 min)
4. TinyTapeout submission walkthrough (30 min)
5. Silicon risks discussion (10 min)
6. Wrap-up and certificates (10 min)

**Deliverable:** Final GDS ready for fabrication

---

## 📝 ISA Quick Reference

| Opcode | Mnemonic | Operation |
|--------|----------|-----------|
| `0x00` | `NOP` | No operation |
| `0x01` | `LDA imm` | Load immediate → accumulator |
| `0x02` | `ADD imm` | Accumulator + immediate |
| `0x03` | `SUB imm` | Accumulator - immediate |
| `0x04` | `AND imm` | Accumulator AND immediate |
| `0x05` | `OR imm` | Accumulator OR immediate |
| `0x06` | `XOR imm` | Accumulator XOR immediate |
| `0x07` | `NOT` | Bitwise NOT accumulator |
| `0x08` | `STA addr` | Store accumulator → memory |
| `0x09` | `LDM addr` | Load memory → accumulator |
| `0x0A` | `JMP addr` | Jump unconditional |
| `0x0B` | `JZ addr` | Jump if zero flag set |
| `0x0C` | `JNZ addr` | Jump if zero flag clear |
| `0x0D` | `OUT` | Accumulator → GPIO output |
| `0x0E` | `IN` | GPIO input → accumulator |
| `0x0F` | `HLT` | Halt execution |
| `0x10` | `SHL` | Shift left |
| `0x11` | `SHR` | Shift right |
| `0x12` | `INC` | Increment accumulator |
| `0x13` | `DEC` | Decrement accumulator |
| `0x14` | `ADDA addr` | Add memory[addr] to accumulator |
| `0x15` | `SUBA addr` | Sub memory[addr] from accumulator |

Instruction format: `{opcode[15:8], operand[7:0]}` (16-bit wide)

---

## 🔧 Student Modification Guide

### Safe to Modify ✅
- `rtl/core/alu.v` — Add new ALU operations
- `rtl/core/program_rom.v` — Write new programs
- `rtl/gpio.v` — Custom GPIO behavior (LED patterns, etc.)

### Frozen - Do NOT Modify ❌
- `rtl/core/control.v` — CPU state machine
- `rtl/core/regfile.v` — Data memory
- `rtl/soc_top.v` — Top-level wiring

---

## 🔍 Troubleshooting

| Issue | Solution |
|-------|----------|
| `iverilog: command not found` | `sudo apt install iverilog` |
| Testbench fails | Check your ROM program for correct opcodes |
| Synthesis errors | Ensure no latches (all cases covered in ALU) |
| Timing violations | Keep clock ≤ 5 MHz (200ns period) |
| DRC violations | Don't modify frozen modules |

---

## 📚 Resources

- [SKY130 PDK Documentation](https://skywater-pdk.readthedocs.io/)
- [Yosys Manual](https://yosyshq.readthedocs.io/)
- [OpenROAD Documentation](https://openroad.readthedocs.io/)
- [TinyTapeout](https://tinytapeout.com/) — Easiest path to real silicon
- [Efabless/Google MPW](https://efabless.com/) — Free shuttle runs

---

## 📄 License

This workshop is released under the **MIT License**. Use freely for education.
