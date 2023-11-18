module Cpu
  class Cpu
    attr_accessor :cycles, :a, :x, :y, :s, :p, :pc, :mem, :sid

    def initialize(mem, sid: nil)
      @a = 0x00
      @x = 0x00
      @y = 0x00
      @s = 0xff
      @p = 0x34
      @pc = 0x0000
      @cycles = 0

      @mem = mem
      @sid = sid

      reset
    end

    def getmem(addr)
      if addr >= 0x0000 && addr <= 0xffff
        return @mem[addr]
      else
        raise "Invalid memory address: #{addr}"
      end
    end

    def setmem(addr, value)
      if addr >= 0x0000 && addr <= 0xffff
        @mem[addr] = value
      else
        raise "Invalid memory address: #{addr}"
      end
    end

    def pcinc
      pc = @pc
      @pc = (@pc + 1) & 0xffff
      return pc
    end

    # Implement other methods such as getaddr, setaddr, putaddr, setflags, push, pop, branch, reset, step, etc.
    # These methods should implement the CPU's behavior and instructions.

    def reset
      @a = 0x00
      @x = 0x00
      @y = 0x00
      @s = 0xff
      @p = 0x34
      @pc = 0x0000
      @cycles = 0
    end

    def step
      opcode = getmem(pcinc)
      # Implement the CPU instruction decoding and execution logic here based on the opcode.
      # This involves fetching the opcode, decoding it, and executing the corresponding instruction.
      # Update registers, flags, and cycles accordingly.
      
      # For example, you can decode and execute instructions using a case statement:
      case opcode
      when 0x00
        # Execute NOP instruction
        # Update registers, flags, and cycles as needed
      when 0x01
        # Execute LDA instruction
        # Update registers, flags, and cycles as needed
      # Add more instructions as needed
      else
        # Handle unknown opcode
        raise "Unknown opcode: #{opcode}"
      end
    end

    # Implement additional CPU functionality here as needed
    # For example, methods for addressing modes, stack operations, flags, etc.
  end
end
