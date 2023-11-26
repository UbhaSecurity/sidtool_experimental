module SidtoolExperimental
  class Mos6510
    class Cpu
      # Accessors for interacting with the CPU's memory and registers from outside the class.
      attr_accessor :memory, :registers, :state
      # Define constant flags used in the status register (P).
      module Flags
        CARRY = 0x01
        ZERO = 0x02
        INTERRUPT_DISABLE = 0x04
        DECIMAL = 0x08
        BREAK = 0x10
        UNUSED = 0x20
        OVERFLOW = 0x40
        NEGATIVE = 0x80
      end

      # Define addressing modes for instructions.
       module Mode
        IMP = 0   # Implied
        ACC = 1   # Accumulator
        IMM = 2   # Immediate
        ZP  = 3   # Zero Page
        ZPX = 4   # Zero Page, X-indexed
        ZPY = 5   # Zero Page, Y-indexed
        ABS = 6   # Absolute
        ABX = 7   # Absolute, X-indexed
        ABY = 8   # Absolute, Y-indexed
        IND = 9   # Indirect
        IZX = 10  # Indexed Indirect (X)
        IZY = 11  # Indirect Indexed (Y)
        REL = 12  # Relative
      end

      # Accessor methods for registers, providing a clean way to access CPU registers.
      def a; @registers[:A]; end
      def x; @registers[:X]; end
      def y; @registers[:Y]; end
      def p; @registers[:P]; end
      def pc; @registers[:PC]; end

      # Initialize the CPU with provided memory and set up initial state.
      def initialize(mem)
        raise "Memory not initialized" if mem.nil?
        
        @memory = mem
        @registers = {
          A: 0x00, 
          X: 0x00, 
          Y: 0x00, 
          SP: 0xFF, 
          P: Flags::INTERRUPT_DISABLE | Flags::BREAK
        }

        # Initialize the Program Counter (PC) using memory reads
        @PC = @memory.read(0xFFFC) | (@memory.read(0xFFFD) << 8)

        @cycles = 0
        reset
        @state = SidtoolExperimental::State.new(self) # Initialize the state with a reference to this CPU.
        initialize_instructions # Initialize the instruction set for this instance
        @halt = false  # Initialize the @halt variable
      end


      # Reset method to reinitialize registers to default values.
      def reset
        @registers[:A] = 0
        @registers[:X] = 0
        @registers[:Y] = 0
        @registers[:SP] = 0xFF
        @registers[:P] = Flags::INTERRUPT_DISABLE | Flags::BREAK
        @registers[:PC] = read_memory(0xFFFC) | (read_memory(0xFFFD) << 8) # Set PC from reset vector.
        @cycles = 0
      end

      def brk
      # Increment PC by one to simulate the CPU's behavior of reading the next byte (which is ignored)
      @registers[:PC] = (@registers[:PC] + 1) & 0xFFFF

      # Push PC to stack
      push_stack((@registers[:PC] >> 8) & 0xFF) # Push high byte of PC to stack
      push_stack(@registers[:PC] & 0xFF)        # Push low byte of PC to stack

      # Set Break flag before pushing
      set_flag(Flags::BREAK)

      # Push processor status to stack with Break and Unused flags set
      push_stack(@registers[:P] | Flags::BREAK | Flags::UNUSED)

      # Load the IRQ interrupt vector into the PC
      @registers[:PC] = read_memory(0xFFFE) | (read_memory(0xFFFF) << 8)

      # Set the interrupt disable flag to prevent further IRQs
      set_flag(Flags::INTERRUPT_DISABLE)
      end

      # Implement the step method to execute a single CPU instruction.
      def step
        opc = fetch_byte
        instr = @instructions[opc]

      if instr.nil?
        handle_illegal_opcode(opc)
      else
        @cycles += instr[:cycles]
        @cycles += 1 if page_boundary_crossed?(instr)
        @cycles += 1 if branch_taken?(instr)

        instr[:operation].call
      end
        @state.update
        handle_timer_interrupts
      end

    
def handle_timer_interrupts
  @state.cia_timers.each do |timer|
    if timer.underflow? && timer.interrupt_enabled?
      irq
      timer.clear_underflow # Reset underflow flag after handling interrupt
    end
  end
end


    # ORA (OR with Accumulator)
    def ora(value)
      @registers[:A] |= value                  # OR the value with the accumulator
      update_flags(@registers[:A])             # Update the flags based on the result
    end

def load_register_immediate(register)
  value = fetch_byte
  @registers[register] = value
  update_zero_and_negative_flags(@registers[register])
end


   # Load the accumulator with a value using immediate addressing mode.
  def lda_immediate
    load_register_immediate('A')
  end

  # Load the X register with a value using immediate addressing mode.
  def ldx_immediate
    load_register_immediate('X')
  end

  # Load the Y register with a value using immediate addressing mode.
  def ldy_immediate
    load_register_immediate(:Y)
  end


  # Implement the Store Accumulator (STA) instruction with zero page addressing mode
  def sta_zero_page
    address = fetch_byte
    write_memory(address, @registers[:A])
  end

  # Implement the Store Accumulator (STA) instruction with zero page X addressing mode
  def sta_zero_page_x
    address = (fetch_byte + @registers[:X]) & 0xFF
    write_memory(address, @registers[:A])
  end

  # Implement the Store Accumulator (STA) instruction with absolute addressing mode
  def sta_absolute
    address = fetch_word
    write_memory(address, @registers[:A])
  end

  # Implement the Store Accumulator (STA) instruction with absolute X addressing mode
  def sta_absolute_x
    address = (fetch_word + @registers[:X]) & 0xFFFF
    write_memory(address, @registers[:A])
  end

  # Implement the Store Accumulator (STA) instruction with absolute Y addressing mode
  def sta_absolute_y
    address = (fetch_word + @registers[:Y]) & 0xFFFF
    write_memory(address, @registers[:A])
  end

      # EOR (Exclusive OR)
      def eor(value)
        @registers[:A] ^= value  # Perform XOR with the accumulator
        update_flags(@registers[:A])  # Update the flags based on the result
      end


  # Implement the Store Accumulator (STA) instruction with indexed indirect addressing mode
  def sta_indexed_indirect
    zp_address = fetch_byte
    zp_address_x = (zp_address + @registers[:X]) & 0xFF
    address = read_memory(zp_address_x) | (read_memory((zp_address_x + 1) & 0xFF) << 8)
    write_memory(address, @registers[:A])
  end

  # Implement the Store Accumulator (STA) instruction with indirect indexed addressing mode
  def sta_indirect_indexed
    zp_address = fetch_byte
    address = read_memory(zp_address) | (read_memory((zp_address + 1) & 0xFF) << 8)
    address += @registers[:Y]
    write_memory(address, @registers[:A])
  end

  # Implement the Transfer Accumulator to X (TAX) instruction
  def tax
    @registers[:X] = @registers[:A]
    update_flags(@registers[:X])
  end

  # Implement the Transfer Accumulator to Y (TAY) instruction
  def tay
    @registers[:Y] = @registers[:A]
    update_flags(@registers[:Y])
  end

  # Implement the Transfer X to Accumulator (TXA) instruction
  def txa
    @registers[:A] = @registers[:X]
    update_flags(@registers[:A])
  end

  # Implement the Transfer Y to Accumulator (TYA) instruction
  def tya
    @registers[:A] = @registers[:Y]
    update_flags(@registers[:A])
  end

  # Implement the Transfer Stack Pointer to X (TSX) instruction
  def tsx
    @registers[:X] = @registers[:SP]
    update_flags(@registers[:X])
  end

  # Implement the Transfer X to Stack Pointer (TXS) instruction
  def txs
    @registers[:SP] = @registers[:X]
  end

  # Implement the Increment X (INX) instruction
  def inx
    @registers[:X] = (@registers[:X] + 1) & 0xFF
    update_flags(@registers[:X])
  end

  # Implement the Increment Y (INY) instruction
  def iny
    @registers[:Y] = (@registers[:Y] + 1) & 0xFF
    update_flags(@registers[:Y])
  end

  # Implement the Decrement X (DEX) instruction
  def dex
    @registers[:X] = (@registers[:X] - 1) & 0xFF
    update_flags(@registers[:X])
  end

    # LSR (Logical Shift Right)
      def lsr(mode)
        address, value = get_address_and_value(mode)
        carry_flag_set = value & 0x01 == 0x01
        value >>= 1  # Shift right by one bit

        # Update the carry flag based on the old 0th bit
        carry_flag_set ? set_flag(Flags::CARRY) : clear_flag(Flags::CARRY)
        
        # Update the Zero and Negative flags
        update_flags(value)

        set_memory_or_accumulator(mode, address, value)
      end


# RTI (Return from Interrupt)
      def rti
        # Pop processor status from the stack
        status = pop_stack
        @registers[:P] = status & ~Flags::BREAK  # Clear the BREAK flag upon popping

        # Pop program counter from the stack
        low_byte = pop_stack
        high_byte = pop_stack
        @registers[:PC] = (high_byte << 8) | low_byte
      end

      # JMP (Jump)
      def jmp(mode)
        address = get_address(mode)
        @registers[:PC] = address
      end

      # AND (bitwise AND with accumulator)
      def and(value)
        # Perform bitwise AND operation
        @registers[:A] &= value

        # Update flags based on the result
        update_zero_and_negative_flags(@registers[:A])
      end

      # ROR (Rotate Right)
      def ror(mode)
        address = get_address(mode)
        value = address.nil? ? @registers[:A] : read_memory(address)

        new_carry = value & 0x01
        value = (value >> 1) | ((@registers[:P] & Flags::CARRY) << 7)

        if address.nil?
          @registers[:A] = value
        else
          write_memory(address, value)
        end

        update_flags(value)

        # Update the carry flag
        if new_carry == 1
          set_flag(Flags::CARRY)
        else
          clear_flag(Flags::CARRY)
        end
      end

      # Jump to Subroutine (JSR)
      def jsr
        # Fetch the target address where the subroutine is located.
        target_address = fetch_word

        # Calculate the return address (current PC - 1, because PC is already pointing to the next instruction after JSR)
        return_address = @registers[:PC] - 1

        # Push the high byte and then the low byte of the return address onto the stack
        push_stack((return_address >> 8) & 0xFF)  # High byte
        push_stack(return_address & 0xFF)        # Low byte

        # Set the program counter to the target address
        @registers[:PC] = target_address
      end

 # Arithmetic Shift Left (ASL)
      def asl(mode)
        case mode
        when Mode::ACC
          asl_accumulator
        when Mode::ZP
          asl_zero_page
        when Mode::ZPX
          asl_zero_page_x
        when Mode::ABS
          asl_absolute
        when Mode::ABX
          asl_absolute_x
        else
          raise "Unhandled addressing mode for ASL: #{mode}"
        end
      end


  def dec(mode)
    address = get_address(mode)
    value = read_memory(address) - 1
    set_address(mode, value)
    update_flags(value)
  end

  def inc(mode)
    address = get_address(mode)
    value = read_memory(address) + 1
    set_address(mode, value)
    update_flags(value)
  end

   # Define initialize_instructions method
      def initialize_instructions
        @instructions = {
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
  0xFE => { operation: method(:inc), addr_mode: Mode::ABX, cycles: 7 }
}
      end

def pc_increment
  @registers[:PC] = (@registers[:PC] + 1) & 0xFFFF
end

# ROL (Rotate Left)
      def rol(mode)
        value = get_value(mode) # Get the value based on addressing mode
        carry = @registers[:P] & Flags::CARRY

        # Shift left by one and add the old carry flag to bit 0
        result = (value << 1) | carry

        # Set the new carry flag based on the old bit 7
        if value & 0x80 != 0
          @registers[:P] |= Flags::CARRY
        else
          @registers[:P] &= ~Flags::CARRY
        end

        # Update the result in the accumulator or memory
        set_value(mode, result & 0xFF)

        # Update the Zero and Negative flags
        update_flags(result)
      end

     # RTS (Return from Subroutine)
      def rts
        # Retrieve the return address from the stack
        low_byte = pop_stack
        high_byte = pop_stack
        return_address = (high_byte << 8) | low_byte

        # The return address is the byte after the JSR instruction, so increment by 1
        @registers[:PC] = return_address + 1
      end

  # Implement the Decrement Y (DEY) instruction
  def dey
    @registers[:Y] = (@registers[:Y] - 1) & 0xFF
    update_flags(@registers[:Y])
  end

  # Implement the Push Accumulator (PHA) instruction
  def pha
    push_stack(@registers[:A])
  end

  # Implement the Pop Accumulator (PLA) instruction
  def pla
    @registers[:A] = pop_stack
    update_flags(@registers[:A])
  end

  # Implement the Push Processor Status (PHP) instruction
  def php
    status = @registers[:P] | Flags::BREAK
    push_stack(status)
  end

  # Implement the Pop Processor Status (PLP) instruction
  def plp
    status = pop_stack
    @registers[:P] = status & ~Flags::BREAK  # Clear the BREAK flag upon popping
  end

  # Implement the Branch if Carry Clear (BCC) instruction
      def bcc
        branch(@registers[:P] & Flags::CARRY == 0)
      end

      # Implement the Branch if Carry Set (BCS) instruction
      def bcs
        branch(@registers[:P] & Flags::CARRY != 0)
      end

      # Implement the Branch if Equal (BEQ) instruction
      def beq
        branch(@registers[:P] & Flags::ZERO != 0)
      end

      # Implement the Branch if Negative (BMI) instruction
      def bmi
        branch(@registers[:P] & Flags::NEGATIVE != 0)
      end

      # Implement the Branch if Not Equal (BNE) instruction
      def bne
        branch(@registers[:P] & Flags::ZERO == 0)
      end

      # Implement the Branch if Positive (BPL) instruction
      def bpl
        branch(@registers[:P] & Flags::NEGATIVE == 0)
      end

      # Implement the Branch if Overflow Clear (BVC) instruction
      def bvc
        branch(@registers[:P] & Flags::OVERFLOW == 0)
      end

      # Implement the Branch if Overflow Set (BVS) instruction
      def bvs
        branch(@registers[:P] & Flags::OVERFLOW != 0)
      end

  # BIT (test bits in memory with accumulator)
      def bit(value)
        # Perform bitwise AND operation but do not change the accumulator
        result = @registers[:A] & value

        # Update the Zero flag (set if the AND result is zero)
        if result == 0
          @registers[:P] |= Flags::ZERO
        else
          @registers[:P] &= ~Flags::ZERO
        end

        # Update the Negative flag based on bit 7 of the memory value
        if value & 0x80 != 0
          @registers[:P] |= Flags::NEGATIVE
        else
          @registers[:P] &= ~Flags::NEGATIVE
        end

        # Update the Overflow flag based on bit 6 of the memory value
        if value & 0x40 != 0
          @registers[:P] |= Flags::OVERFLOW
        else
          @registers[:P] &= ~Flags::OVERFLOW
        end
      end

    
def adc(value)
  if @registers[:P] & Flags::DECIMAL != 0
    # Decimal mode
    a_low = @registers[:A] & 0x0F
    a_high = @registers[:A] >> 4
    value_low = value & 0x0F
    value_high = value >> 4

    sum_low = a_low + value_low + (@registers[:P] & Flags::CARRY)
    sum_high = a_high + value_high + (sum_low > 0x09 ? 1 : 0)

    if sum_low > 0x09
      sum_low -= 0x0A
    end

    if sum_high > 0x09
      sum_high -= 0x0A
      @registers[:P] |= Flags::CARRY
    else
      @registers[:P] &= ~Flags::CARRY
    end

    @registers[:A] = (sum_high << 4) | sum_low
  else
    # Binary mode
    sum = @registers[:A] + value + (@registers[:P] & Flags::CARRY)
    if sum > 0xFF
      @registers[:P] |= Flags::CARRY
    else
      @registers[:P] &= ~Flags::CARRY
    end

    @registers[:A] = sum & 0xFF
  end

  # Update Zero and Negative flags
  update_flags(@registers[:A])
end

def sbc(value)
  if @registers[:P] & Flags::DECIMAL != 0
    # Decimal mode
    a_low = @registers[:A] & 0x0F
    a_high = @registers[:A] >> 4
    value_low = value & 0x0F
    value_high = value >> 4

    borrow = (@registers[:P] & Flags::CARRY == 0) ? 1 : 0
    sum_low = a_low - value_low - borrow
    sum_high = a_high - value_high - (sum_low < 0 ? 1 : 0)

    if sum_low < 0
      sum_low += 0x0A
    end

    if sum_high < 0
      sum_high += 0x0A
      @registers[:P] &= ~Flags::CARRY
    else
      @registers[:P] |= Flags::CARRY
    end

    @registers[:A] = (sum_high << 4) | sum_low
  else
    # Binary mode
    value = ~value & 0xFF  # Invert value for subtraction
    sum = @registers[:A] - value - ((@registers[:P] & Flags::CARRY == 0) ? 1 : 0)
    if sum < 0
      @registers[:P] &= ~Flags::CARRY
    else
      @registers[:P] |= Flags::CARRY
    end
    @registers[:A] = sum & 0xFF
  end
  # Update Zero and Negative flags
  update_flags(@registers[:A])
end

def set_flag(flag)
  @registers[:P] |= flag
end

def clear_flag(flag)
  @registers[:P] &= ~flag
end


def clc
  @registers[:P] &= ~Flags::CARRY
end

def sec
  @registers[:P] |= Flags::CARRY
end

def cli
  @registers[:P] &= ~Flags::INTERRUPT_DISABLE
end

def sei
  @registers[:P] |= Flags::INTERRUPT_DISABLE
end

def update_flags(value)
  # Clear existing Zero and Negative flags
  @registers[:P] &= ~(Flags::ZERO | Flags::NEGATIVE)

  # Set the Zero flag if the value is 0
  @registers[:P] |= Flags::ZERO if value == 0

  # Set the Negative flag if bit 7 of the value is set
  @registers[:P] |= Flags::NEGATIVE if value & 0x80 != 0

  # Handle Overflow flag (this is a placeholder, actual implementation depends on your CPU's logic)
  if some_overflow_condition
    @registers[:P] |= Flags::OVERFLOW
  else
    @registers[:P] &= ~Flags::OVERFLOW
  end
end


def nmi
  # Push the program counter and processor status to the stack
  push_stack((@registers[:PC] >> 8) & 0xFF)
  push_stack(@registers[:PC] & 0xFF)
  push_stack(@registers[:P] & ~Flags::BREAK)

  # Set the program counter to the NMI vector
  @registers[:PC] = read_memory(0xFFFA) | (read_memory(0xFFFB) << 8)

  # Set the interrupt disable flag
  @registers[:P] |= Flags::INTERRUPT_DISABLE
end

def set_address(mode, value)
  case mode
  when Mode::ABS
    @cycles += 2
    ad = read_memory(pc - 2)
    ad |= read_memory(pc - 1) << 8
    set_mem(ad, value)
  when Mode::ABSX
    @cycles += 3
    ad = read_memory(pc - 2)
    ad |= read_memory(pc - 1) << 8
    ad2 = ad + @x
    ad2 &= 0xffff
    @cycles -= 1 if (ad2 & 0xff00) != (ad & 0xff00)
    set_mem(ad2, value)
  when Mode::ABSY
    @cycles += 3
    ad = read_memory(pc - 2)
    ad |= read_memory(pc - 1) << 8
    ad2 = ad + @y
    ad2 &= 0xffff
    @cycles -= 1 if (ad2 & 0xff00) != (ad & 0xff00)
    set_mem(ad2, value)
  when Mode::ZP
    @cycles += 2
    ad = read_memory(pc - 1)
    set_mem(ad, value)
  when Mode::ZPX
    @cycles += 2
    ad = read_memory(pc - 1)
    ad += @x
    set_mem(ad & 0xff, value)
  when Mode::ZPY
    @cycles += 2
    ad = read_memory(pc - 1)
    ad += @y
    set_mem(ad & 0xff, value)
  when Mode::INDY
    @cycles += 3
    ad = read_memory(pc - 1)
    ad2 = read_memory(ad)
    ad2 |= read_memory((ad + 1) & 0xff) << 8
    ad2 = ad2 + @y
    ad2 &= 0xffff
    set_mem(ad2, value)
  when Mode::INDX
    @cycles += 3
    zero_page_addr = (read_memory(pc - 1) + @x) & 0xff
    effective_addr = read_memory(zero_page_addr) | (read_memory((zero_page_addr + 1) & 0xff) << 8)
    set_mem(effective_addr, value)
  when Mode::ACC
    @a = value
  when Mode::IND
    @cycles += 4
    ad = read_memory(pc - 2)
    ad |= read_memory(pc - 1) << 8
    ad2 = (ad & 0xFF00) | ((ad + 1) & 0x00FF)
    set_mem(ad, value)
    set_mem(ad2, value >> 8)
  else
    raise "Unhandled addressing mode: #{mode}"
  end
end

def irq
  return if (@registers[:P] & Flags::INTERRUPT_DISABLE) != 0

  # Push the program counter and processor status to the stack
  push_stack((@registers[:PC] >> 8) & 0xFF)
  push_stack(@registers[:PC] & 0xFF)
  push_stack(@registers[:P] | Flags::BREAK)

  # Set the program counter to the IRQ vector
  @registers[:PC] = read_memory(0xFFFE) | (read_memory(0xFFFF) << 8)

  # Set the interrupt disable flag
  @registers[:P] |= Flags::INTERRUPT_DISABLE
end

def get_address(mode)
  case mode
  when Mode::IMP
    nil # Implied mode does not use an address
  when Mode::IMM
    pc_increment # Immediate mode uses the next byte as a value
  when Mode::ABS
    low_byte = read_memory(pc_increment)
    high_byte = read_memory(pc_increment)
    (high_byte << 8) | low_byte
  when Mode::ABSX
    base_address = get_address(Mode::ABS)
    (base_address + @registers[:X]) & 0xFFFF
  when Mode::ABSY
    base_address = get_address(Mode::ABS)
    (base_address + @registers[:Y]) & 0xFFFF
  when Mode::ZP
    read_memory(pc_increment)
  when Mode::ZPX
    (read_memory(pc_increment) + @registers[:X]) & 0xFF
  when Mode::ZPY
    (read_memory(pc_increment) + @registers[:Y]) & 0xFF
  when Mode::INDX
    zero_page_addr = (read_memory(pc_increment) + @registers[:X]) & 0xFF
    low_byte = read_memory(zero_page_addr)
    high_byte = read_memory((zero_page_addr + 1) & 0xFF)
    (high_byte << 8) | low_byte
  when Mode::INDY
    base_address = read_memory(pc_increment)
    low_byte = read_memory(base_address)
    high_byte = read_memory((base_address + 1) & 0xFF)
    ((high_byte << 8) | low_byte) + @registers[:Y]
  when Mode::IND
    base_address = get_address(Mode::ABS)
    low_byte = read_memory(base_address)
    high_byte = read_memory((base_address & 0xFF00) | ((base_address + 1) & 0xFF))
    (high_byte << 8) | low_byte
  when Mode::ACC
    nil # Accumulator mode does not use a memory address
  when Mode::REL
    offset = read_memory(pc_increment)
    (offset < 0x80 ? offset : offset - 0x100) + @registers[:PC]
  else
    raise "Unhandled addressing mode: #{mode}"
  end

  # Implement the Interrupt Request (IRQ) instruction
  def irq
    interrupt(0xFFFE)
  end

  # Implement the Non-Maskable Interrupt (NMI) instruction
  def nmi
    interrupt(0xFFFA)
  end

  # Implement the Software Interrupt (SWI/BRK) instruction
  def swi
    push_stack(@registers[:P][:value] | 0x10)
    push_stack(@registers[:PC] >> 8)
    push_stack(@registers[:PC] & 0xFF)
    @registers[:P][:I] = 1
    @registers[:PC] = read_memory(0xFFFF) << 8 | read_memory(0xFFFE)
  end

  # Implement the Return from Interrupt (RTI) instruction
  def rti
    status = pop_stack
    @registers[:P] = FlagsRegister.new(status)
    low_byte = pop_stack
    high_byte = pop_stack
    @registers[:PC] = (high_byte << 8) | low_byte
  end

# Helper method to perform a branch instruction
def branch(condition)
  offset = fetch_byte
  if condition
    new_pc = (@registers[:PC] + offset).to_i
    # Check if the branch crosses a page boundary
    if new_pc & 0xFF00 != @registers[:PC] & 0xFF00
      @cycles += 2
    else
      @cycles += 1
    end
    @registers[:PC] = new_pc & 0xFFFF
  end
end

# Helper method to perform an interrupt
def interrupt(vector_address)
  push_stack(@registers[:PC] >> 8)
  push_stack(@registers[:PC] & 0xFF)
  push_stack(@registers[:P][:value] | 0x10)
  @registers[:P][:I] = 1
  @registers[:PC] = read_memory(vector_address) << 8 | read_memory(vector_address - 1)
end

# Create an instance of the CPU
cpu = CPU.new

# Load a program into memory (you need to define this method)
# load_program(cpu, program)

# Execute the program
cpu.execute

# Print the final state of the CPU
puts cpu

end



# No Operation
def nop
  # Do nothing
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

def stx(mode)
  address = get_address(mode)
  set_address(mode, @registers[:X])
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

def sty(mode)
  address = get_address(mode)
  set_address(mode, @registers[:Y])
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

# Load Accumulator from Ab Ensure that all methods, modules, and classesolute, X-Indexed Memory
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

# Absolute, Y-Indexed Addressing Mode:

# Load Accumulator from Absolute, Y-Indexed Memory
def lda_absolute_y
  absolute_address = fetch_word
  absolute_address += @y
  @a = read_memory(absolute_address)
  update_flags(@a)
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

# Add a method to execute the program
def execute_program(program)
  @memory = program.dup
  @registers[:PC] = correct_start_address # Replace with the correct start address
  @registers[:SP] = 0xFF
  until @halt
    execute_next_instruction
  end
end

# Method to perform the AND operation
def and_operation(value)
  # Perform bitwise AND between the accumulator and the value
  @registers[:A] &= value
  # Update Zero and Negative flags
  update_flags(@registers[:A])
end

def execute_next_instruction
  opcode = fetch_byte
  case opcode
  when 0x00 then brk
  when 0x01 then ora_indexed_indirect
  when 0x05 then ora_zero_page
  when 0x06 then asl_zero_page
  when 0x08 then php
  when 0x09 then ora_immediate
  when 0x0A then asl_accumulator
  when 0x0D then ora_absolute
  when 0x0E then asl_absolute
  when 0x10 then bpl
  when 0x11 then ora_indirect_indexed
  when 0x15 then ora_zero_page_x
  when 0x16 then asl_zero_page_x
  when 0x18 then clc
  when 0x19 then ora_absolute_y
  when 0x1D then ora_absolute_x
  when 0x1E then asl_absolute_x
  when 0x20 then jsr
  when 0x21 then and_indexed_indirect
  when 0x24 then bit_zero_page
  when 0x25 then and_zero_page
  when 0x26 then rol_zero_page
  when 0x28 then plp
  when 0x29 then and_immediate
  when 0x2A then rol_accumulator
  when 0x2C then bit_absolute
  when 0x2D then and_absolute
  when 0x2E then rol_absolute
  when 0x30 then bmi
  when 0x31 then and_indirect_indexed
  when 0x35 then and_zero_page_x
  when 0x36 then rol_zero_page_x
  when 0x38 then sec
  when 0x39 then and_absolute_y
  when 0x3D then and_absolute_x
  when 0x3E then rol_absolute_x
  when 0x40 then rti
  when 0x41 then eor_indexed_indirect
  when 0x45 then eor_zero_page
  when 0x46 then lsr_zero_page
  when 0x48 then pha
  when 0x49 then eor_immediate
  when 0x4A then lsr_accumulator
  when 0x4C then jmp_absolute
  when 0x4D then eor_absolute
  when 0x4E then lsr_absolute
  when 0x50 then bvc
  when 0x51 then eor_indirect_indexed
  when 0x55 then eor_zero_page_x
  when 0x56 then lsr_zero_page_x
  when 0x58 then cli
  when 0x59 then eor_absolute_y
  when 0x5D then eor_absolute_x
  when 0x5E then lsr_absolute_x
  when 0x60 then rts
  when 0x61 then adc_indexed_indirect
  when 0x65 then adc_zero_page
  when 0x66 then ror_zero_page
  when 0x68 then pla
  when 0x69 then adc_immediate
  when 0x6A then ror_accumulator
  when 0x6C then jmp_indirect
  when 0x6D then adc_absolute
  when 0x6E then ror_absolute
  when 0x70 then bvs
  when 0x71 then adc_indirect_indexed
  when 0x75 then adc_zero_page_x
  when 0x76 then ror_zero_page_x
  when 0x78 then sei
  when 0x79 then adc_absolute_y
  when 0x7D then adc_absolute_x
  when 0x7E then ror_absolute_x
  when 0x81 then sta_indexed_indirect
  when 0x84 then sty_zero_page
  when 0x85 then sta_zero_page
  when 0x86 then stx_zero_page
  when 0x88 then dey
  when 0x8A then txa
  when 0x8C then sty_absolute
  when 0x8D then sta_absolute
  when 0x8E then stx_absolute
  when 0x90 then bcc
  when 0x91 then sta_indirect_indexed
  when 0x94 then sty_zero_page_x
  when 0x95 then sta_zero_page_x
  when 0x96 then stx_zero_page_y
  when 0x98 then tya
  when 0x99 then sta_absolute_y
  when 0x9A then txs
  when 0x9D then sta_absolute_x
  when 0xA0 then ldy_immediate
  when 0xA1 then lda_indexed_indirect
  when 0xA2 then ldx_immediate
  when 0xA4 then ldy_zero_page
  when 0xA5 then lda_zero_page
  when 0xA6 then ldx_zero_page
  when 0xA8 then tay
  when 0xA9 then lda_immediate
  when 0xAA then tax
  when 0xAC then ldy_absolute
  when 0xAD then lda_absolute
  when 0xAE then ldx_absolute
  when 0xB0 then bcs
  when 0xB1 then lda_indirect_indexed
  when 0xB4 then ldy_zero_page_x
  when 0xB5 then lda_zero_page_x
  when 0xB6 then ldx_zero_page_y
  when 0xB8 then clv
  when 0xB9 then lda_absolute_y
  when 0xBA then tsx
  when 0xBC then ldy_absolute_x
  when 0xBD then lda_absolute_x
  when 0xBE then ldx_absolute_y
  when 0xC0 then cpy_immediate
  when 0xC1 then cmp_indexed_indirect
  when 0xC4 then cpy_zero_page
  when 0xC5 then cmp_zero_page
  when 0xC6 then dec_zero_page
  when 0xC8 then iny
  when 0xC9 then cmp_immediate
  when 0xCA then dex
  when 0xCC then cpy_absolute
  when 0xCD then cmp_absolute
  when 0xCE then dec_absolute
  when 0xD0 then bne
  when 0xD1 then cmp_indirect_indexed
  when 0xD5 then cmp_zero_page_x
  when 0xD6 then dec_zero_page_x
  when 0xD8 then cld
  when 0xD9 then cmp_absolute_y
  when 0xDD then cmp_absolute_x
  when 0xDE then dec_absolute_x
  when 0xE0 then cpx_immediate
  when 0xE1 then sbc_indexed_indirect
  when 0xE4 then cpx_zero_page
  when 0xE5 then sbc_zero_page
  when 0xE6 then inc_zero_page
  when 0xE8 then inx
  when 0xE9 then sbc_immediate
  when 0xEA then nop
  when 0xEC then cpx_absolute
  when 0xED then sbc_absolute
  when 0xEE then inc_absolute
  when 0xF0 then beq
  when 0xF1 then sbc_indirect_indexed
  when 0xF5 then sbc_zero_page_x
  when 0xF6 then inc_zero_page_x
  when 0xF8 then sed
  when 0xF9 then sbc_absolute_y
  when 0xFD then sbc_absolute_x
  when 0xFE then inc_absolute_x
  else
    handle_unknown_opcode(opcode)
  end
end

      def execute
        while !@halt
          execute_next_instruction
        end
      end

    end
  end
end

    def run_cycles(cyc)
      while @cycles < cyc
        step
      end
    end

  private

 def get_value(mode)
        case mode
        when Mode::ACC
          @registers[:A] # Accumulator mode
        else
          address = get_address(mode)
          read_memory(address) # For other addressing modes
        end
      end

      def set_value(mode, value)
        case mode
        when Mode::ACC
          @registers[:A] = value # Accumulator mode
        else
          address = get_address(mode)
          write_memory(address, value) # For other addressing modes
        end
      end


     # Update zero and negative flags based on the given value
      def update_zero_and_negative_flags(value)
        # Update Zero flag (set if value is zero)
        if value == 0
          @registers[:P] |= Flags::ZERO
        else
          @registers[:P] &= ~Flags::ZERO
        end

        # Update Negative flag (set if bit 7 of value is set)
        if value & 0x80 != 0
          @registers[:P] |= Flags::NEGATIVE
        else
          @registers[:P] &= ~Flags::NEGATIVE
        end
      end


      # Method to read a byte from memory
      def read_memory(address)
        @memory.read(address)
      end

      # Method to write a byte to memory
      def write_memory(address, value)
        @memory.write(address, value)
      end

def pc_increment
  @registers[:PC] = (@registers[:PC] + 1) & 0xFFFF
end

def fetch_byte
  byte = memory[pc]
  pc_increment
  byte
end

def fetch_word
  low_byte = fetch_byte
  high_byte = fetch_byte
  (high_byte << 8) | low_byte
end

  def validate_address(address)
    unless address >= 0x0000 && address <= 0xFFFF
      raise "Invalid memory address: 0x#{address.to_s(16)}"
    end
  end

    # Define a method to handle illegal opcodes.
    def handle_illegal_opcode(opcode)
      puts "Warning: Illegal opcode 0x#{opcode.to_s(16)} encountered at address 0x#{pc.to_s(16)}"
      # Actions for illegal opcode can be customized here.
    end

# Push a value to the stack
def push_stack(value)
  @memory[@registers[:SP] + 0x0100] = value
  @registers[:SP] = (@registers[:SP] - 1) & 0xFF
end

# Pop a value from the stack
def pop_stack
  @registers[:SP] = (@registers[:SP] + 1) & 0xFF
  @memory[@registers[:SP] + 0x0100]
end

# Check if a page boundary is crossed, which affects cycle count.
def page_boundary_crossed?(instruction)
  case instruction[:addr_mode]
  when Mode::ABSX
    base_address = fetch_word
    crossed = (base_address & 0xFF00) != ((base_address + @registers[:X]) & 0xFF00)
  when Mode::ABSY
    base_address = fetch_word
    crossed = (base_address & 0xFF00) != ((base_address + @registers[:Y]) & 0xFF00)
  when Mode::INDY
    zp_address = fetch_byte
    base_address = read_memory(zp_address) | (read_memory((zp_address + 1) & 0xFF) << 8)
    crossed = (base_address & 0xFF00) != ((base_address + @registers[:Y]) & 0xFF00)
  else
    crossed = false
  end
  crossed
end

 # ASL for the Accumulator
      def asl_accumulator
        value = @registers[:A]
        result = value << 1
        update_carry_flag(result)
        @registers[:A] = result & 0xFF
        update_zero_and_negative_flags(@registers[:A])
      end

      # ASL for Zero Page Addressing
      def asl_zero_page
        address = fetch_byte
        value = read_memory(address)
        result = value << 1
        update_carry_flag(result)
        write_memory(address, result & 0xFF)
        update_zero_and_negative_flags(result)
      end

  # Helper method to update carry flag
      def update_carry_flag(value)
        if value > 0xFF
          set_flag(Flags::CARRY)
        else
          clear_flag(Flags::CARRY)
        end
      end

      # Helper method to update zero and negative flags
      def update_zero_and_negative_flags(value)
        set_flag(Flags::ZERO) if value == 0
        set_flag(Flags::NEGATIVE) if value & 0x80 != 0
      end

def branch_taken?(instruction)
  return false unless instruction[:addr_mode] == Mode::REL

  offset = fetch_byte
  case instruction[:operation]
  when :bpl
    condition = @registers[:P] & Flags::NEGATIVE == 0
  when :bmi
    condition = @registers[:P] & Flags::NEGATIVE != 0
  when :bvc
    condition = @registers[:P] & Flags::OVERFLOW == 0
  when :bvs
    condition = @registers[:P] & Flags::OVERFLOW != 0
  when :bcc
    condition = @registers[:P] & Flags::CARRY == 0
  when :bcs
    condition = @registers[:P] & Flags::CARRY != 0
  when :bne
    condition = @registers[:P] & Flags::ZERO == 0
  when :beq
    condition = @registers[:P] & Flags::ZERO != 0
  else
    raise "Unsupported branch operation"
  end

     # Method to get the address and value based on the addressing mode
      def get_address_and_value(mode)
        case mode
        when Mode::ACC
          [nil, @registers[:A]]
        else
          address = get_address(mode)
          [address, read_memory(address)]
        end
      end

      # Method to set the value back to memory or accumulator based on the addressing mode
      def set_memory_or_accumulator(mode, address, value)
        case mode
        when Mode::ACC
          @registers[:A] = value
        else
          write_memory(address, value)
        end
      end

   # Method to get the address based on the addressing mode
      def get_address(mode)
        case mode
        when Mode::ABS
          fetch_word
        when Mode::IND
          address = fetch_word
          low_byte = read_memory(address)
          high_byte = read_memory((address & 0xFF00) | ((address + 1) & 0xFF))
          (high_byte << 8) | low_byte
        else
          raise "Unsupported addressing mode for JMP: #{mode}"
        end
      end

  # Update the program counter if the condition is true
  if condition
    new_pc = @registers[:PC] + offset
    new_pc -= 0x0100 if offset >= 0x80 # Handle negative offsets
    @registers[:PC] = new_pc & 0xFFFF
    true # Indicates a branch was taken
  else
    false # Indicates no branch was taken
  end
end
