module Mos6510
   INSTRUCTIONS = {
  0x00 => { operation: method(:brk), addr_mode: Mode::IMP, cycles: 7 },
  0x01 => { operation: method(:ora), addr_mode: Mode::IZX, cycles: 6 },
  0x05 => { operation: method(:ora), addr_mode: Mode::ZP, cycles: 3 },
  0x06 => { operation: method(:asl), addr_mode: Mode::ZP, cycles: 5 },
  0x08 => { operation: method(:php), addr_mode: Mode::IMP, cycles: 3 },
  0x09 => { operation: method(:ora), addr_mode: Mode::IMM, cycles: 2 },
  0x0A => { operation: method(:asl), addr_mode: Mode::ACC, cycles: 2 },
  0x0D => { operation: method(:ora), addr_mode: Mode::ABS, cycles: 4 },
  0x0E => { operation: method(:asl), addr_mode: Mode::ABS, cycles: 6 },
  0x10 => { operation: method(:bpl), addr_mode: Mode::REL, cycles: 2 },
  0x11 => { operation: method(:ora), addr_mode: Mode::IZY, cycles: 5 },
  0x15 => { operation: method(:ora), addr_mode: Mode::ZPX, cycles: 4 },
  0x16 => { operation: method(:asl), addr_mode: Mode::ZPX, cycles: 6 },
  0x18 => { operation: method(:clc), addr_mode: Mode::IMP, cycles: 2 },
  0x19 => { operation: method(:ora), addr_mode: Mode::ABY, cycles: 4 },
  0x1D => { operation: method(:ora), addr_mode: Mode::ABX, cycles: 4 },
  0x1E => { operation: method(:asl), addr_mode: Mode::ABX, cycles: 7 },
  0x20 => { operation: method(:jsr), addr_mode: Mode::ABS, cycles: 6 },
  0x21 => { operation: method(:and), addr_mode: Mode::IZX, cycles: 6 },
  0x24 => { operation: method(:bit), addr_mode: Mode::ZP, cycles: 3 },
  0x25 => { operation: method(:and), addr_mode: Mode::ZP, cycles: 3 },
  0x26 => { operation: method(:rol), addr_mode: Mode::ZP, cycles: 5 },
  0x28 => { operation: method(:plp), addr_mode: Mode::IMP, cycles: 4 },
  0x29 => { operation: method(:and), addr_mode: Mode::IMM, cycles: 2 },
  0x2A => { operation: method(:rol), addr_mode: Mode::ACC, cycles: 2 },
  0x2C => { operation: method(:bit), addr_mode: Mode::ABS, cycles: 4 },
  0x2D => { operation: method(:and), addr_mode: Mode::ABS, cycles: 4 },
  0x2E => { operation: method(:rol), addr_mode: Mode::ABS, cycles: 6 },
  0x30 => { operation: method(:bmi), addr_mode: Mode::REL, cycles: 2 },
  0x31 => { operation: method(:and), addr_mode: Mode::IZY, cycles: 5 },
  0x35 => { operation: method(:and), addr_mode: Mode::ZPX, cycles: 4 },
  0x36 => { operation: method(:rol), addr_mode: Mode::ZPX, cycles: 6 },
  0x38 => { operation: method(:sec), addr_mode: Mode::IMP, cycles: 2 },
  0x39 => { operation: method(:and), addr_mode: Mode::ABY, cycles: 4 },
  0x3D => { operation: method(:and), addr_mode: Mode::ABX, cycles: 4 },
  0x3E => { operation: method(:rol), addr_mode: Mode::ABX, cycles: 7 },
   0x40 => { operation: method(:rti), addr_mode: Mode::IMP, cycles: 6 },
  0x41 => { operation: method(:eor), addr_mode: Mode::IZX, cycles: 6 },
  0x45 => { operation: method(:eor), addr_mode: Mode::ZP, cycles: 3 },
  0x46 => { operation: method(:lsr), addr_mode: Mode::ZP, cycles: 5 },
  0x48 => { operation: method(:pha), addr_mode: Mode::IMP, cycles: 3 },
  0x49 => { operation: method(:eor), addr_mode: Mode::IMM, cycles: 2 },
  0x4A => { operation: method(:lsr), addr_mode: Mode::ACC, cycles: 2 },
  0x4C => { operation: method(:jmp), addr_mode: Mode::ABS, cycles: 3 },
  0x4D => { operation: method(:eor), addr_mode: Mode::ABS, cycles: 4 },
  0x4E => { operation: method(:lsr), addr_mode: Mode::ABS, cycles: 6 },
  0x50 => { operation: method(:bvc), addr_mode: Mode::REL, cycles: 2 },
  0x51 => { operation: method(:eor), addr_mode: Mode::IZY, cycles: 5 },
  0x55 => { operation: method(:eor), addr_mode: Mode::ZPX, cycles: 4 },
  0x56 => { operation: method(:lsr), addr_mode: Mode::ZPX, cycles: 6 },
  0x58 => { operation: method(:cli), addr_mode: Mode::IMP, cycles: 2 },
  0x59 => { operation: method(:eor), addr_mode: Mode::ABY, cycles: 4 },
  0x5D => { operation: method(:eor), addr_mode: Mode::ABX, cycles: 4 },
  0x5E => { operation: method(:lsr), addr_mode: Mode::ABX, cycles: 7 },
  0x60 => { operation: method(:rts), addr_mode: Mode::IMP, cycles: 6 },
  0x61 => { operation: method(:adc), addr_mode: Mode::IZX, cycles: 6 },
  0x65 => { operation: method(:adc), addr_mode: Mode::ZP, cycles: 3 },
  0x66 => { operation: method(:ror), addr_mode: Mode::ZP, cycles: 5 },
  0x68 => { operation: method(:pla), addr_mode: Mode::IMP, cycles: 4 },
  0x69 => { operation: method(:adc), addr_mode: Mode::IMM, cycles: 2 },
  0x6A => { operation: method(:ror), addr_mode: Mode::ACC, cycles: 2 },
  0x6C => { operation: method(:jmp), addr_mode: Mode::IND, cycles: 5 },
  0x6D => { operation: method(:adc), addr_mode: Mode::ABS, cycles: 4 },
  0x6E => { operation: method(:ror), addr_mode: Mode::ABS, cycles: 6 },
  0x70 => { operation: method(:bvs), addr_mode: Mode::REL, cycles: 2 },
  0x71 => { operation: method(:adc), addr_mode: Mode::IZY, cycles: 5 },
  0x75 => { operation: method(:adc), addr_mode: Mode::ZPX, cycles: 4 },
  0x76 => { operation: method(:ror), addr_mode: Mode::ZPX, cycles: 6 },
  0x78 => { operation: method(:sei), addr_mode: Mode::IMP, cycles: 2 },
  0x79 => { operation: method(:adc), addr_mode: Mode::ABY, cycles: 4 },
  0x7D => { operation: method(:adc), addr_mode: Mode::ABX, cycles: 4 },
  0x7E => { operation: method(:ror), addr_mode: Mode::ABX, cycles: 7 },
  0x81 => { operation: method(:sta), addr_mode: Mode::IZX, cycles: 6 },
  0x84 => { operation: method(:sty), addr_mode: Mode::ZP, cycles: 3 },
  0x85 => { operation: method(:sta), addr_mode: Mode::ZP, cycles: 3 },
  0x86 => { operation: method(:stx), addr_mode: Mode::ZP, cycles: 3 },
  0x88 => { operation: method(:dey), addr_mode: Mode::IMP, cycles: 2 },
  0x8A => { operation: method(:txa), addr_mode: Mode::IMP, cycles: 2 },
  0x8C => { operation: method(:sty), addr_mode: Mode::ABS, cycles: 4 },
  0x8D => { operation: method(:sta), addr_mode: Mode::ABS, cycles: 4 },
  0x8E => { operation: method(:stx), addr_mode: Mode::ABS, cycles: 4 },
  0x90 => { operation: method(:bcc), addr_mode: Mode::REL, cycles: 2 },
  0x91 => { operation: method(:sta), addr_mode: Mode::IZY, cycles: 6 },
  0x94 => { operation: method(:sty), addr_mode: Mode::ZPX, cycles: 4 },
  0x95 => { operation: method(:sta), addr_mode: Mode::ZPX, cycles: 4 },
  0x96 => { operation: method(:stx), addr_mode: Mode::ZPY, cycles: 4 },
  0x98 => { operation: method(:tya), addr_mode: Mode::IMP, cycles: 2 },
  0x99 => { operation: method(:sta), addr_mode: Mode::ABY, cycles: 5 },
  0x9A => { operation: method(:txs), addr_mode: Mode::IMP, cycles: 2 },
  0x9D => { operation: method(:sta), addr_mode: Mode::ABX, cycles: 5 },
  0xA0 => { operation: method(:ldy), addr_mode: Mode::IMM, cycles: 2 },
  0xA1 => { operation: method(:lda), addr_mode: Mode::IZX, cycles: 6 },
  0xA2 => { operation: method(:ldx), addr_mode: Mode::IMM, cycles: 2 },
  0xA4 => { operation: method(:ldy), addr_mode: Mode::ZP, cycles: 3 },
  0xA5 => { operation: method(:lda), addr_mode: Mode::ZP, cycles: 3 },
  0xA6 => { operation: method(:ldx), addr_mode: Mode::ZP, cycles: 3 },
  0xA8 => { operation: method(:tay), addr_mode: Mode::IMP, cycles: 2 },
  0xA9 => { operation: method(:lda), addr_mode: Mode::IMM, cycles: 2 },
  0xAA => { operation: method(:tax), addr_mode: Mode::IMP, cycles: 2 },
  0xAC => { operation: method(:ldy), addr_mode: Mode::ABS, cycles: 4 },
  0xAD => { operation: method(:lda), addr_mode: Mode::ABS, cycles: 4 },
  0xAE => { operation: method(:ldx), addr_mode: Mode::ABS, cycles: 4 },
  0xB0 => { operation: method(:bcs), addr_mode: Mode::REL, cycles: 2 },
  0xB1 => { operation: method(:lda), addr_mode: Mode::IZY, cycles: 5 },
  0xB4 => { operation: method(:ldy), addr_mode: Mode::ZPX, cycles: 4 },
  0xB5 => { operation: method(:lda), addr_mode: Mode::ZPX, cycles: 4 },
  0xB6 => { operation: method(:ldx), addr_mode: Mode::ZPY, cycles: 4 },
  0xB8 => { operation: method(:clv), addr_mode: Mode::IMP, cycles: 2 },
  0xB9 => { operation: method(:lda), addr_mode: Mode::ABY, cycles: 4 },
  0xBA => { operation: method(:tsx), addr_mode: Mode::IMP, cycles: 2 },
  0xBC => { operation: method(:ldy), addr_mode: Mode::ABX, cycles: 4 },
  0xBD => { operation: method(:lda), addr_mode: Mode::ABX, cycles: 4 },
  0xBE => { operation: method(:ldx), addr_mode: Mode::ABY, cycles: 4 },
  0xC0 => { operation: method(:cpy), addr_mode: Mode::IMM, cycles: 2 },
  0xC1 => { operation: method(:cmp), addr_mode: Mode::IZX, cycles: 6 },
  0xC4 => { operation: method(:cpy), addr_mode: Mode::ZP, cycles: 3 },
  0xC5 => { operation: method(:cmp), addr_mode: Mode::ZP, cycles: 3 },
  0xC6 => { operation: method(:dec), addr_mode: Mode::ZP, cycles: 5 },
  0xC8 => { operation: method(:iny), addr_mode: Mode::IMP, cycles: 2 },
  0xC9 => { operation: method(:cmp), addr_mode: Mode::IMM, cycles: 2 },
  0xCA => { operation: method(:dex), addr_mode: Mode::IMP, cycles: 2 },
  0xCC => { operation: method(:cpy), addr_mode: Mode::ABS, cycles: 4 },
  0xCD => { operation: method(:cmp), addr_mode: Mode::ABS, cycles: 4 },
  0xCE => { operation: method(:dec), addr_mode: Mode::ABS, cycles: 6 },
  0xD0 => { operation: method(:bne), addr_mode: Mode::REL, cycles: 2 },
  0xD1 => { operation: method(:cmp), addr_mode: Mode::IZY, cycles: 5 },
  0xD5 => { operation: method(:cmp), addr_mode: Mode::ZPX, cycles: 4 },
  0xD6 => { operation: method(:dec), addr_mode: Mode::ZPX, cycles: 6 },
  0xD8 => { operation: method(:cld), addr_mode: Mode::IMP, cycles: 2 },
  0xD9 => { operation: method(:cmp), addr_mode: Mode::ABY, cycles: 4 },
  0xDD => { operation: method(:cmp), addr_mode: Mode::ABX, cycles: 4 },
  0xDE => { operation: method(:dec), addr_mode: Mode::ABX, cycles: 7 },
  0xE0 => { operation: method(:cpx), addr_mode: Mode::IMM, cycles: 2 },
  0xE1 => { operation: method(:sbc), addr_mode: Mode::IZX, cycles: 6 },
  0xE4 => { operation: method(:cpx), addr_mode: Mode::ZP, cycles: 3 },
  0xE5 => { operation: method(:sbc), addr_mode: Mode::ZP, cycles: 3 },
  0xE6 => { operation: method(:inc), addr_mode: Mode::ZP, cycles: 5 },
  0xE8 => { operation: method(:inx), addr_mode: Mode::IMP, cycles: 2 },
  0xE9 => { operation: method(:sbc), addr_mode: Mode::IMM, cycles: 2 },
  0xEA => { operation: method(:nop), addr_mode: Mode::IMP, cycles: 2 },
  0xEC => { operation: method(:cpx), addr_mode: Mode::ABS, cycles: 4 },
  0xED => { operation: method(:sbc), addr_mode: Mode::ABS, cycles: 4 },
  0xEE => { operation: method(:inc), addr_mode: Mode::ABS, cycles: 6 },
  0xF0 => { operation: method(:beq), addr_mode: Mode::REL, cycles: 2 },
  0xF1 => { operation: method(:sbc), addr_mode: Mode::IZY, cycles: 5 },
  0xF5 => { operation: method(:sbc), addr_mode: Mode::ZPX, cycles: 4 },
  0xF6 => { operation: method(:inc), addr_mode: Mode::ZPX, cycles: 6 },
  0xF8 => { operation: method(:sed), addr_mode: Mode::IMP, cycles: 2 },
  0xF9 => { operation: method(:sbc), addr_mode: Mode::ABY, cycles: 4 },
  0xFD => { operation: method(:sbc), addr_mode: Mode::ABX, cycles: 4 },
  0xFE => { operation: method(:inc), addr_mode: Mode::ABX, cycles: 7 },
 0x100 => { operation: method(:nop), addr_mode: Mode::ZPX, cycles: 4 },
 0x101 => { operation: method(:sbc), addr_mode: Mode::IZX, cycles: 6 },
 0x102 => { operation: method(:nop), addr_mode: Mode::IMM, cycles: 2 },
 0x103 => { operation: method(:nop), addr_mode: Mode::IZX, cycles: 8 },
 0x104 => { operation: method(:nop), addr_mode: Mode::ZP, cycles: 3 },
 0x105 => { operation: method(:sbc), addr_mode: Mode::ZP, cycles: 3 },
 0x106 => { operation: method(:inc), addr_mode: Mode::ZP, cycles: 5 },
 0x107 => { operation: method(:sbc), addr_mode: Mode::ZP, cycles: 5 },
 0x108 => { operation: method(:nop), addr_mode: Mode::IMM, cycles: 2 },
 0x109 => { operation: method(:sbc), addr_mode: Mode::IMM, cycles: 2 },
 0x10A => { operation: method(:nop), addr_mode: Mode::IMM, cycles: 2 },
 0x10B => { operation: method(:sbc), addr_mode: Mode::IMM, cycles: 2 },
 0x10C => { operation: method(:nop), addr_mode: Mode::ABS, cycles: 4 },
 0x10D => { operation: method(:sbc), addr_mode: Mode::ABS, cycles: 4 },
 0x10E => { operation: method(:inc), addr_mode: Mode::ABS, cycles: 6 },
 0x10F => { operation: method(:sbc), addr_mode: Mode::ABS, cycles: 6 },
 0x110 => { operation: method(:nop), addr_mode: Mode::REL, cycles: 2 },
 0x111 => { operation: method(:sbc), addr_mode: Mode::IZY, cycles: 5 },
 0x112 => { operation: method(:sbc), addr_mode: Mode::IZX, cycles: 5 },
 0x113 => { operation: method(:sbc), addr_mode: Mode::IZY, cycles: 5 },
 0x114 => { operation: method(:nop), addr_mode: Mode::ZPX, cycles: 4 },
 0x115 => { operation: method(:sbc), addr_mode: Mode::ZPX, cycles: 4 },
 0x116 => { operation: method(:inc), addr_mode: Mode::ZPX, cycles: 6 },
 0x117 => { operation: method(:sbc), addr_mode: Mode::ZPX, cycles: 6 },
 0x118 => { operation: method(:sed), addr_mode: Mode::IMP, cycles: 2 },
 0x119 => { operation: method(:sbc), addr_mode: Mode::ABY, cycles: 4 },
 0x11A => { operation: method(:nop), addr_mode: Mode::IMP, cycles: 2 },
 0x11B => { operation: method(:sbc), addr_mode: Mode::ABY, cycles: 4 },
 0x11C => { operation: method(:nop), addr_mode: Mode::ABX, cycles: 4 },
 0x11D => { operation: method(:sbc), addr_mode: Mode::ABX, cycles: 4 },
 0x11E => { operation: method(:inc), addr_mode: Mode::ABX, cycles: 7 },
 0x11F => { operation: method(:sbc), addr_mode: Mode::ABX, cycles: 7 }
}
  class Cpu
    attr_accessor :a, :x, :y, :s, :p, :pc, :mem

    def initialize(mem)
      @a = 0x00
      @x = 0x00
      @y = 0x00
      @s = 0xff
      @p = 0x34
      @pc = 0x0000

      @mem = mem

      reset
    end

    def reset
      @a = 0x00
      @x = 0x00
      @y = 0x00
      @s = 0xff
      @p = 0x34
      @pc = 0x0000
    end

    # Add other methods and functionality as needed
  end

  class CpuController
    def initialize(sid: nil)
      @memory = [0] * 65536
      @sid = sid
    end

    def load(bytes, from: 0)
      bytes.each_with_index do |byte, index|
        @memory[from + index] = byte
      end
    end

    def start
      @cpu = Cpu.new(@memory)  # Create an instance of Mos6510::Cpu
    end

    def jsr(address, accumulator_value=0)
      @cpu.jsr(address, accumulator_value)
    end

    def step
      @cpu.step
    end

    def pc
      @cpu.pc
    end

    def pc=(new_pc)
      @cpu.pc = new_pc
    end

    def peek(address)
      @cpu.getmem(address)
    end
  end
end

  class Mos6510
    def set_mem(addr, value)
      if (0..65535).cover?(addr) && (0..255).cover?(value)
        if (0xd400..0xd41b).cover?(addr) && @sid
          @sid.poke(addr & 0x1f, value)
          @sid.poke_digi(addr, value) if addr > 0xd418
        else
          @mem[addr] = value
        end
      else
        raise "Out of range address or value"
      end
    end

    def pc_increment
      old_pc = @pc
      @pc = (@pc + 1) & 0xffff
      old_pc
    end

def get_address(mode)
  case mode
  when Mode::IMP
    @cycles += 2
    0
  when Mode::IMM
    @cycles += 2
    get_mem(pc_increment)
  when Mode::ABS
    @cycles += 4
    ad = get_mem(pc_increment)
    ad |= get_mem(pc_increment) << 8
    get_mem(ad)
  when Mode::ABSX
    @cycles += 4
    ad = get_mem(pc_increment)
    ad |= get_mem(pc_increment) << 8
    ad2 = ad + @x
    ad2 &= 0xffff
    @cycles += 1 if (ad2 & 0xff00) != (ad & 0xff00)
    get_mem(ad2)
  when Mode::ABSY
    @cycles += 4
    ad = get_mem(pc_increment)
    ad |= get_mem(pc_increment) << 8
    ad2 = ad + @y
    ad2 &= 0xffff
    @cycles += 1 if (ad2 & 0xff00) != (ad & 0xff00)
    get_mem(ad2)
  when Mode::ZP
    @cycles += 3
    ad = get_mem(pc_increment)
    get_mem(ad)
  when Mode::ZPX
    @cycles += 4
    ad = get_mem(pc_increment)
    ad += @x
    get_mem(ad & 0xff)
  when Mode::ZPY
    @cycles += 4
    ad = get_mem(pc_increment)
    ad += @y
    get_mem(ad & 0xff)
  when Mode::INDX
    @cycles += 6
    ad = get_mem(pc_increment)
    ad += @x
    ad2 = get_mem(ad & 0xff)
    ad += 1
    ad2 |= get_mem(ad & 0xff) << 8
    get_mem(ad2)
  when Mode::INDY
    @cycles += 5
    ad = get_mem(pc_increment)
    ad2 = get_mem(ad)
    ad2 |= get_mem((ad + 1) & 0xff) << 8
    ad = ad2 + @y
    ad &= 0xffff
    @cycles += 1 if (ad2 & 0xff00) != (ad & 0xff00)
    get_mem(ad)
  when Mode::IND
    @cycles += 5
    ad = get_mem(pc_increment)
    ad |= get_mem(pc_increment) << 8
    ad2 = (ad & 0xFF00) | ((ad + 1) & 0x00FF)
    lo = get_mem(ad)
    hi = get_mem(ad2)
    (hi << 8) | lo
  when Mode::ACC
    @cycles += 2
    @a
  when Mode::REL
    @cycles += 2
    offset = get_mem(pc_increment)
    offset = (offset & 0x80) == 0 ? offset : (offset | 0xFF00)
    pc + offset
  else
    raise "Unhandled addressing mode: #{mode}"
  end
end

def set_address(mode, value)
  case mode
  when Mode::ABS
    @cycles += 2
    ad = get_mem(pc - 2)
    ad |= get_mem(pc - 1) << 8
    set_mem(ad, value)
  when Mode::ABSX
    @cycles += 3
    ad = get_mem(pc - 2)
    ad |= get_mem(pc - 1) << 8
    ad2 = ad + @x
    ad2 &= 0xffff
    @cycles -= 1 if (ad2 & 0xff00) != (ad & 0xff00)
    set_mem(ad2, value)
  when Mode::ABSY
    @cycles += 3
    ad = get_mem(pc - 2)
    ad |= get_mem(pc - 1) << 8
    ad2 = ad + @y
    ad2 &= 0xffff
    @cycles -= 1 if (ad2 & 0xff00) != (ad & 0xff00)
    set_mem(ad2, value)
  when Mode::ZP
    @cycles += 2
    ad = get_mem(pc - 1)
    set_mem(ad, value)
  when Mode::ZPX
    @cycles += 2
    ad = get_mem(pc - 1)
    ad += @x
    set_mem(ad & 0xff, value)
  when Mode::ZPY
    @cycles += 2
    ad = get_mem(pc - 1)
    ad += @y
    set_mem(ad & 0xff, value)
  when Mode::INDY
    @cycles += 3
    ad = get_mem(pc - 1)
    ad2 = get_mem(ad)
    ad2 |= get_mem((ad + 1) & 0xff) << 8
    ad2 = ad2 + @y
    ad2 &= 0xffff
    set_mem(ad2, value)
  when Mode::INDX
    @cycles += 3
    zero_page_addr = (get_mem(pc - 1) + @x) & 0xff
    effective_addr = get_mem(zero_page_addr) | (get_mem((zero_page_addr + 1) & 0xff) << 8)
    set_mem(effective_addr, value)
  when Mode::ACC
    @a = value
  when Mode::IND
    @cycles += 4
    ad = get_mem(pc - 2)
    ad |= get_mem(pc - 1) << 8
    ad2 = (ad & 0xFF00) | ((ad + 1) & 0x00FF)
    set_mem(ad, value)
    set_mem(ad2, value >> 8)
  else
    raise "Unhandled addressing mode: #{mode}"
  end
end

# Implied Addressing Mode:

# Clear Carry Flag
def clc
  @p &= ~CARRY_FLAG
end

# Set Carry Flag
def sec
  @p |= CARRY_FLAG
end

# Clear Interrupt Disable Flag
def cli
  @p &= ~INTERRUPT_DISABLE_FLAG
end

# Set Interrupt Disable Flag
def sei
  @p |= INTERRUPT_DISABLE_FLAG
end

# No Operation
def nop
  # Do nothing
end

# Immediate Addressing Mode:

# Load Accumulator with Immediate Value
def lda_immediate
  @a = fetch_byte
  update_flags(@a)
end

# Load X Register with Immediate Value
def ldx_immediate
  @x = fetch_byte
  update_flags(@x)
end

# Load Y Register with Immediate Value
def ldy_immediate
  @y = fetch_byte
  update_flags(@y)
end

# Zero Page Addressing Mode:

# Load Accumulator from Zero-Page Memory
def lda_zero_page
  zero_page_address = fetch_byte
  @a = read_memory(zero_page_address)
  update_flags(@a)
end

# Load X Register from Zero-Page Memory
def ldx_zero_page
  zero_page_address = fetch_byte
  @x = read_memory(zero_page_address)
  update_flags(@x)
end

# Load Y Register from Zero-Page Memory
def ldy_zero_page
  zero_page_address = fetch_byte
  @y = read_memory(zero_page_address)
  update_flags(@y)
end

# Store Accumulator to Zero-Page Memory
def sta_zero_page
  zero_page_address = fetch_byte
  write_memory(zero_page_address, @a)
end

# Store X Register to Zero-Page Memory
def stx_zero_page
  zero_page_address = fetch_byte
  write_memory(zero_page_address, @x)
end

# Store Y Register to Zero-Page Memory
def sty_zero_page
  zero_page_address = fetch_byte
  write_memory(zero_page_address, @y)
end

# Zero Page, X-Indexed Addressing Mode:

# Load Accumulator from Zero-Page, X-Indexed Memory
def lda_zero_page_x
  zero_page_address = (fetch_byte + @x) & 0xFF
  @a = read_memory(zero_page_address)
  update_flags(@a)
end

# Load Y Register from Zero-Page, X-Indexed Memory
def ldy_zero_page_x
  zero_page_address = (fetch_byte + @x) & 0xFF
  @y = read_memory(zero_page_address)
  update_flags(@y)
end

# Store Accumulator to Zero-Page, X-Indexed Memory
def sta_zero_page_x
  zero_page_address = (fetch_byte + @x) & 0xFF
  write_memory(zero_page_address, @a)
end

# Zero Page, Y-Indexed Addressing Mode:

# Load Accumulator from Zero-Page, Y-Indexed Memory
def lda_zero_page_y
  zero_page_address = (fetch_byte + @y) & 0xFF
  @a = read_memory(zero_page_address)
  update_flags(@a)
end

# Store X Register to Zero-Page, Y-Indexed Memory
def stx_zero_page_y
  zero_page_address = (fetch_byte + @y) & 0xFF
  write_memory(zero_page_address, @x)
end

# Absolute Addressing Mode:

# Load Accumulator from Absolute Memory
def lda_absolute
  absolute_address = fetch_word
  @a = read_memory(absolute_address)
  update_flags(@a)
end

# Load X Register from Absolute Memory
def ldx_absolute
  absolute_address = fetch_word
  @x = read_memory(absolute_address)
  update_flags(@x)
end

# Load Y Register from Absolute Memory
def ldy_absolute
  absolute_address = fetch_word
  @y = read_memory(absolute_address)
  update_flags(@y)
end

# Store Accumulator to Absolute Memory
def sta_absolute
  absolute_address = fetch_word
  write_memory(absolute_address, @a)
end

# Store X Register to Absolute Memory
def stx_absolute
  absolute_address = fetch_word
  write_memory(absolute_address, @x)
end

# Store Y Register to Absolute Memory
def sty_absolute
  absolute_address = fetch_word
  write_memory(absolute_address, @y)
end

# Absolute, X-Indexed Addressing Mode:

# Load Accumulator from Absolute, X-Indexed Memory
def lda_absolute_x
  absolute_address = fetch_word
  absolute_address += @x
  @a = read_memory(absolute_address)
  update_flags(@a)
end

# Load Y Register from Absolute, X-Indexed Memory
def ldy_absolute_x
  absolute_address = fetch_word
  absolute_address += @x
  @y = read_memory(absolute_address)
  update_flags(@y)
end

# Store Accumulator to Absolute, X-Indexed Memory
def sta_absolute_x
  absolute_address = fetch_word
  absolute_address += @x
  write_memory(absolute_address, @a)
end

# Absolute, Y-Indexed Addressing Mode:

# Load Accumulator from Absolute, Y-Indexed Memory
def lda_absolute_y
  absolute_address = fetch_word
  absolute_address += @y
  @a = read_memory(absolute_address)
  update_flags(@a)
end

# Store Accumulator to Absolute, Y-Indexed Memory
def sta_absolute_y
  absolute_address = fetch_word
  absolute_address += @y
  write_memory(absolute_address, @a)
end

# Indirect Addressing Mode:

# Jump to Indirect Address
def jmp_indirect
  indirect_address = fetch_word
  jump_address = read_word(indirect_address)
  @pc = jump_address
end

# Indexed Indirect Addressing Mode (Zero Page, X-Indexed):

# Load Accumulator from Indexed Indirect, X-Indexed Memory
def lda_indexed_indirect_x
  zero_page_address = (fetch_byte + @x) & 0xFF
  indirect_address = read_word(zero_page_address)
  @a = read_memory(indirect_address)
  update_flags(@a)
end

# Store Accumulator to Indexed Indirect, X-Indexed Memory
def sta_indexed_indirect_x
  zero_page_address = (fetch_byte + @x) & 0xFF
  indirect_address = read_word(zero_page_address)
  write_memory(indirect_address, @a)
end

# Indirect Indexed Addressing Mode (Zero Page, Y-Indexed):

# Load Accumulator from Indirect Indexed, Y-Indexed Memory
def lda_indirect_indexed_y
  zero_page_address = fetch_byte
  indirect_address = read_word(zero_page_address)
  indirect_address += @y
  @a = read_memory(indirect_address)
  update_flags(@a)
end

# Store Accumulator to Indirect Indexed, Y-Indexed Memory
def sta_indirect_indexed_y
  zero_page_address = fetch_byte
  indirect_address = read_word(zero_page_address)
  indirect_address += @y
  write_memory(indirect_address, @a)
end

def fetch_byte
  value = get_mem(@pc)
  @pc += 1
  value
end

    def step
      opc = fetch_byte
      instr = INSTRUCTIONS[opc]
      if instr.nil?
        raise "Illegal opcode #{opc.to_s(16)}"
      else
        @cycles += instr[:cycles]
        @cycles += 1 if (instr[:addr_mode] == Mode::INDX) && ((@x + fetch_byte) & 0xff00 != (@x & 0xff00))
        @cycles += 1 if (instr[:addr_mode] == Mode::INDY) && ((@y + fetch_byte) & 0xff00 != (@y & 0xff00))
        instr[:operation].call
      end
    end

    def reset
      @a = 0
      @x = 0
      @y = 0
      @s = 0xff
      @p = Flags::IRQ_DISABLE | Flags::BREAK
      @pc = get_mem(0xfffc) | (get_mem(0xfffd) << 8)
      @cycles = 0
    end

    def run_cycles(cyc)
      while @cycles < cyc
        step
      end
    end

    module Flags
      CARRY = 0x01
      ZERO = 0x02
      IRQ_DISABLE = 0x04
      DECIMAL = 0x08
      BREAK = 0x10
      UNUSED = 0x20
      OVERFLOW = 0x40
      NEGATIVE = 0x80
    end

    module Mode
      IMP = 0
      IMM = 1
      ABS = 2
      ABSX = 3
      ABSY = 4
      ZP = 5
      ZPX = 6
      ZPY = 7
      INDX = 8
      INDY = 9
      ACC = 10
    end
  end
