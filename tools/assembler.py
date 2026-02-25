#!/usr/bin/env python3
"""
Simple Assembler for the 8-bit Accumulator MCU
===============================================
Converts assembly text into Verilog ROM initialization.

Usage:
    python3 tools/assembler.py program.asm > rtl/core/program_snippet.v
    python3 tools/assembler.py program.asm --hex > rom/program.hex

Example input (program.asm):
    LDA 5
    ADD 3
    OUT
    HLT

Example output (Verilog):
    rom[0] = 16'h01_05;  // LDA  #5
    rom[1] = 16'h02_03;  // ADD  #3
    rom[2] = 16'h0D_00;  // OUT
    rom[3] = 16'h0F_00;  // HLT
"""

import sys
import re

# Opcode table
OPCODES = {
    'NOP':  0x00,
    'LDA':  0x01,
    'ADD':  0x02,
    'SUB':  0x03,
    'AND':  0x04,
    'OR':   0x05,
    'XOR':  0x06,
    'NOT':  0x07,
    'STA':  0x08,
    'LDM':  0x09,
    'JMP':  0x0A,
    'JZ':   0x0B,
    'JNZ':  0x0C,
    'OUT':  0x0D,
    'IN':   0x0E,
    'HLT':  0x0F,
    'SHL':  0x10,
    'SHR':  0x11,
    'INC':  0x12,
    'DEC':  0x13,
    'ADDA': 0x14,
    'SUBA': 0x15,
}

# Instructions that take no operand
NO_OPERAND = {'NOP', 'NOT', 'OUT', 'IN', 'HLT', 'SHL', 'SHR', 'INC', 'DEC'}


def parse_number(s):
    """Parse a number: decimal, 0x hex, or 0b binary."""
    s = s.strip()
    if s.startswith('0x') or s.startswith('0X'):
        return int(s, 16)
    elif s.startswith('0b') or s.startswith('0B'):
        return int(s, 2)
    else:
        return int(s)


def assemble(lines):
    """Assemble lines of text into (address, opcode, operand, comment) tuples."""
    instructions = []
    labels = {}
    addr = 0

    # First pass: collect labels
    for line in lines:
        line = line.split(';')[0].strip()  # Remove comments
        if not line:
            continue
        if line.endswith(':'):
            labels[line[:-1].strip()] = addr
            continue
        addr += 1

    # Second pass: assemble
    addr = 0
    for raw_line in lines:
        comment = ''
        if ';' in raw_line:
            comment = raw_line[raw_line.index(';'):]
        line = raw_line.split(';')[0].strip()
        if not line or line.endswith(':'):
            continue

        parts = line.split(None, 1)
        mnemonic = parts[0].upper()

        if mnemonic not in OPCODES:
            print(f"ERROR: Unknown instruction '{mnemonic}' at address 0x{addr:02X}",
                  file=sys.stderr)
            sys.exit(1)

        opcode = OPCODES[mnemonic]
        operand = 0

        if mnemonic not in NO_OPERAND and len(parts) > 1:
            operand_str = parts[1].strip()
            if operand_str in labels:
                operand = labels[operand_str]
            else:
                try:
                    operand = parse_number(operand_str)
                except ValueError:
                    print(f"ERROR: Invalid operand '{operand_str}' at address 0x{addr:02X}",
                          file=sys.stderr)
                    sys.exit(1)

        if operand < 0 or operand > 255:
            print(f"ERROR: Operand {operand} out of range [0-255] at address 0x{addr:02X}",
                  file=sys.stderr)
            sys.exit(1)

        instructions.append((addr, opcode, operand, mnemonic, comment.strip()))
        addr += 1

    return instructions


def output_verilog(instructions):
    """Output as Verilog ROM initialization."""
    for addr, opcode, operand, mnemonic, comment in instructions:
        if mnemonic in NO_OPERAND:
            asm_comment = f"{mnemonic}"
        else:
            asm_comment = f"{mnemonic:<4s} #{operand}"
        line = f"        rom[{addr}]  = 16'h{opcode:02X}_{operand:02X};  // {asm_comment}"
        if comment:
            line += f"  {comment}"
        print(line)


def output_hex(instructions):
    """Output as hex file (one 16-bit word per line)."""
    for addr, opcode, operand, mnemonic, comment in instructions:
        print(f"{opcode:02X}{operand:02X}")


def main():
    if len(sys.argv) < 2:
        print("Usage: assembler.py <input.asm> [--hex]")
        print("")
        print("Assembles to Verilog ROM format by default.")
        print("Use --hex for plain hex output.")
        sys.exit(1)

    filename = sys.argv[1]
    hex_mode = '--hex' in sys.argv

    with open(filename, 'r') as f:
        lines = f.readlines()

    instructions = assemble(lines)

    if hex_mode:
        output_hex(instructions)
    else:
        print(f"        // Assembled from {filename}")
        print(f"        // {len(instructions)} instructions")
        print()
        output_verilog(instructions)

    print(f"\n// Assembled {len(instructions)} instructions successfully.",
          file=sys.stderr)


if __name__ == '__main__':
    main()
