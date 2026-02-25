# Student Workshop Guide

## 8-bit Microcontroller → Silicon Tapeout

---

## Before You Begin

### Required Software (Session 1)
```bash
# Install Icarus Verilog and GTKWave
sudo apt update
sudo apt install -y iverilog gtkwave

# Verify installation
iverilog -V
gtkwave --version
```

### Get the Repository
```bash
git clone https://github.com/YOUR_INSTRUCTOR/digital_tapeout_workshop.git
cd digital_tapeout_workshop
```

---

## Session 1: RTL Understanding & Simulation

### Step 1: Understand the Architecture

Our CPU has 5 main components:

```
 ┌─────────────────────────────────────────────┐
 │                  soc_top                      │
 │                                               │
 │  ┌───────────┐    ┌──────────────┐           │
 │  │Program ROM│───→│ Control Unit │           │
 │  │(your code)│    │  (3-stage    │           │
 │  └───────────┘    │   FSM)       │           │
 │                   └──┬───┬───┬───┘           │
 │                      │   │   │               │
 │              ┌───────┘   │   └───────┐       │
 │              ▼           ▼           ▼       │
 │         ┌────────┐ ┌────────┐ ┌──────────┐  │
 │         │  ALU   │ │  Data  │ │   GPIO   │──→ PINS
 │         │(modify)│ │  RAM   │ │ (modify) │  │
 │         └────────┘ └────────┘ └──────────┘  │
 └─────────────────────────────────────────────┘
```

Open and read these files in order:
1. `rtl/core/alu.v` — The math engine
2. `rtl/core/program_rom.v` — Your program lives here
3. `rtl/core/control.v` — The CPU brain (read, don't modify)
4. `rtl/soc_top.v` — How everything connects

### Step 2: Run the ALU Unit Test

```bash
make test_alu
```

You should see all 24 tests pass. Open the waveform:
```bash
make wave_alu
```

In GTKWave, add these signals: `a`, `b`, `alu_op`, `result`, `zero_flag`, `carry_flag`.

**What to observe:** Watch how different `alu_op` values produce different results from the same inputs.

### Step 3: Run the GPIO Test

```bash
make test_gpio
```

This verifies the output register latches correctly and input passes through.

### Step 4: Run the Full SoC Test

```bash
make test_soc
```

This runs the demo program (count 1 to 5) and checks GPIO outputs.

```bash
make wave
```

In GTKWave, add these signals:
- `uut.u_ctrl.pc` — Program counter
- `uut.u_ctrl.acc` — Accumulator
- `uut.u_ctrl.state` — FSM state (0=FETCH, 1=DECODE, 2=EXECUTE)
- `uut.u_ctrl.opcode` — Current instruction opcode
- `gpio_out` — Output pins
- `halted` — CPU stopped

**What to observe:**
- Watch PC increment as instructions execute
- See ACC change with each arithmetic operation
- See GPIO output update on each OUT instruction
- Watch the 3-cycle pattern: FETCH→DECODE→EXECUTE

### Step 5: Modify the Program (Your Turn!)

Open `rtl/core/program_rom.v` and try changing the program.

**Simple change:** Make it count to 10 instead of 5:
```verilog
// Change line: rom[4]  = 16'h03_06;  // SUB #6
// To:          rom[4]  = 16'h03_0B;  // SUB #11

// Change line: rom[6]  = 16'h02_06;  // ADD #6
// To:          rom[6]  = 16'h02_0B;  // ADD #11
```

Run `make test_soc` — you'll see GPIO output 1 through 10.

**Note:** The testbench expects 1-5, so some checks will "fail" — that's OK! The program itself is correct. Update the testbench `check_gpio` calls to match.

### Step 6: (Optional) Modify the ALU

Open `rtl/core/alu.v` and add a new operation. For example, add absolute value at opcode `4'hB`:

```verilog
4'hB: result_wide = a[7] ? ({1'b0, ~a} + 9'd1) : {1'b0, a};  // ABS
```

Add a test in `tb/alu_tb.v` and run `make test_alu`.

---

## Session 2: Synthesis & Place-and-Route

### Step 7: Check Tools

```bash
make check_tools
```

Ensure Yosys and OpenROAD are installed.

### Step 8: Synthesize

```bash
make synth
```

This converts your Verilog RTL into SKY130 standard cells (gates).

Examine the output:
```bash
cat outputs/synth_report.txt
```

**Key numbers to look for:**
- Number of cells
- Number of flip-flops (registers)
- Estimated area

### Step 9: Floorplan

```bash
make floorplan
```

This creates the chip's physical boundary and places the power grid.

### Step 10: Place and Route

```bash
make pnr
```

This places all the standard cells and routes the wires between them.

Check for timing violations in the output. At 5 MHz, there should be plenty of slack.

---

## Session 3: Verification & Tapeout

### Step 11: Export GDS

```bash
make gds
```

The GDS file (`outputs/chip.gds`) is the final layout that goes to the foundry.

### Step 12: Run DRC

```bash
make drc
```

Design Rule Check ensures the layout is physically manufacturable.

### Step 13: Run LVS

```bash
make lvs
```

Layout vs Schematic ensures the physical layout matches the logical netlist.

### Step 14: Visual Inspection

Open the layout in Magic:
```bash
magic -rcfile $PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc outputs/chip.gds
```

Zoom in to see:
- Standard cells (tiny rectangles)
- Metal routing layers (colored wires)
- Power rails (thick horizontal stripes)
- I/O pads (large squares at edges)

### Step 15: Submit for Fabrication

**Option A: TinyTapeout** (recommended for workshops)
- Visit [tinytapeout.com](https://tinytapeout.com)
- Follow their GitHub template
- Costs ~$150 per tile for real silicon

**Option B: Efabless MPW** (free but competitive)
- Visit [efabless.com](https://efabless.com)
- Apply for the next open MPW shuttle
- Uses Caravel harness chip

---

## Congratulations! 🎉

You've completed the full digital IC design flow:

```
RTL Code → Simulation → Synthesis → Floorplan → Place & Route → DRC/LVS → GDS
```

This is the same flow used to design every digital chip in the world — from microcontrollers to GPUs to AI accelerators. The tools are different at Intel or TSMC, but the concepts are identical.
