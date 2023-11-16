module Mos6510
  class Mos6510
    attr_accessor :cycles, :a, :x, :y, :s, :p, :pc

    def initialize(mem, sid: nil)
      @mem = mem
      @sid = sid
      reset
    end

    def get_mem(addr)
      @mem[addr]
    end

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
      when Mode::ACC
        @cycles += 2
        @a
      else
        raise "Unhandled addressing mode"
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
      when Mode::ZP
        @cycles += 2
        ad = get_mem(pc - 1)
        set_mem(ad, value)
      when Mode::ZPX
        @cycles += 2
        ad = get_mem(pc - 1)
        ad += @x
        set_mem(ad & 0xff, value)
      when Mode::ACC
        @a = value
      else
        raise "Unhandled addressing mode"
      end
    end

    def fetch_byte
      get_mem(pc_increment)
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

    INSTRUCTIONS = {
      # Add your instruction definitions here.
      # For example:
      # 0x69 => { operation: method(:adc), addr_mode: Mode::IMM, cycles: 2 },
      # 0x65 => { operation: method(:adc), addr_mode: Mode::ZP, cycles: 3 },
    }
  end
end
