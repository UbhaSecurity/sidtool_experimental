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
        IMM = 1   # Immediate
        ABS = 2   # Absolute
        ABSX = 3  # Absolute, X-indexed
        ABSY = 4  # Absolute, Y-indexed
        ZP = 5    # Zero Page
        ZPX = 6   # Zero Page, X-indexed
        ZPY = 7   # Zero Page, Y-indexed
        INDX = 8  # Indexed Indirect
        INDY = 9  # Indirect Indexed
        ACC = 10  # Accumulator
      end

      # Accessor methods for registers, providing a clean way to access CPU registers.
      def a; @registers[:A]; end
      def x; @registers[:X]; end
      def y; @registers[:Y]; end
      def p; @registers[:P]; end
      def pc; @registers[:PC]; end

      # Initialize the CPU with provided memory and set up initial state.
      def initialize(mem)
        @registers = {
          A: 0x00, 
          X: 0x00, 
          Y: 0x00, 
          SP: 0xFF, 
          P: Flags::INTERRUPT_DISABLE | Flags::BREAK,
          PC: mem[0xFFFC] | (mem[0xFFFD] << 8) # Program Counter starts from the reset vector.
        }
        @memory =  mem 
        @cycles = 0
        reset
        @state = SidtoolExperimental::State.new(self) # Initialize the state with a reference to this CPU.
        initialize_instructions # Initialize the instructions set for this instance
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
        opc = fetch_byte # Fetch the opcode from the current PC location.
        instr = @instructions[opc] # Retrieve the instruction details for this instance.

        if instr.nil?
          handle_illegal_opcode(opc) # Handle illegal opcode gracefully.
        else
          @cycles += instr[:cycles] # Add instruction cycles.

          # Check for additional cycles needed for page boundary and branch taken.
          @cycles += 1 if page_boundary_crossed?(instr)
          @cycles += 1 if branch_taken?(instr)

          instr[:operation].call # Execute the instruction.
        end
        @state.update # Update the state (CIA timers, SID, etc.) in each CPU step.
        handle_timer_interrupts # Handle interrupts triggered by CIA timers.
      end
    
def handle_timer_interrupts
  @state.cia_timers.each do
    if @state.cia_timers.last.underflow && (@state.cia_timers.last.control_register & Sidtool::CIATimer::INTERRUPT_FLAG) != 0
      irq # Trigger the IRQ interrupt if conditions are met.
    end
  end
end

    # ORA (OR with Accumulator)
    def ora(value)
      @registers[:A] |= value                  # OR the value with the accumulator
      update_flags(@registers[:A])             # Update the flags based on the result
    end

   def load_register_immediate(register)
    """Load a value into the specified register using immediate addressing mode."""
    value = fetch_byte
    @registers[register] = value
    update_zero_and_negative_flags(registers[register])
   end

  def lda_immediate
    """Load the accumulator with a value using immediate addressing mode."""
    load_register_immediate('A')
  end

  def ldx_immediate
    """Load the X register with a value using immediate addressing mode."""
    load_register_immediate('X')
  end

  def ldy_immediate
    """Load the Y register with a value using immediate addressing mode."""
      oad_register_immediate('Y')
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
    status = @registers[:P][:value] | 0x10
    push_stack(status)
  end

  # Implement the Pop Processor Status (PLP) instruction
  def plp
    status = pop_stack
    @registers[:P] = FlagsRegister.new(status)
  end

  # Implement the Branch if Carry Clear (BCC) instruction
  def bcc
    branch(!@registers[:P][:C])
  end

  # Implement the Branch if Carry Set (BCS) instruction
  def bcs
    branch(@registers[:P][:C])
  end

  # Implement the Branch if Equal (BEQ) instruction
  def beq
    branch(@registers[:P][:Z])
  end

  # Implement the Branch if Negative (BMI) instruction
  def bmi
    branch(@registers[:P][:N])
  end

  # Implement the Branch if Not Equal (BNE) instruction
  def bne
    branch(!@registers[:P][:Z])
  end

  # Implement the Branch if Positive (BPL) instruction
  def bpl
    branch(!@registers[:P][:N])
  end

  # Implement the Branch if Overflow Clear (BVC) instruction
  def bvc
    branch(!@registers[:P][:V])
  end

  # Implement the Branch if Overflow Set (BVS) instruction
  def bvs
    branch(@registers[:P][:V])
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

# Add a method to execute the program
def execute_program(program)
  @memory = program.dup
  @registers[:PC] = 0x0600  # Set the initial program counter (you can adjust this)
  @registers[:SP] = 0xFF  # Set the initial stack pointer

  # Run the CPU until a halt condition is reached
  until @halt
    execute_next_instruction
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
  when 0x01 then ora(get_address(Mode::IZX))
  when 0x05 then ora(get_address(Mode::ZP))
  when 0x06 then asl(get_address(Mode::ZP))
  when 0x08 then php
  when 0x09 then ora(get_address(Mode::IMM))
  when 0x0A then asl_accumulator
  when 0x0D then ora(get_address(Mode::ABS))
  when 0x0E then asl(get_address(Mode::ABS))
  when 0x10 then bpl
  when 0x11 then ora(get_address(Mode::IZY))
  when 0x15 then ora(get_address(Mode::ZPX))
  when 0x16 then asl(get_address(Mode::ZPX))
  when 0x18 then 
  when 0x19 then ora(get_address(Mode::ABY))
  when 0x1D then ora(get_address(Mode::ABX))
  when 0x1E then asl(get_address(Mode::ABX))
  when 0x20 then jsr(get_address(Mode::ABS))
  when 0x21 then and_operation(get_address(Mode::IZX))
  when 0x24 then bit(get_address(Mode::ZP))
  when 0x25 then and_operation(get_address(Mode::ZP))
  when 0x26 then rol(get_address(Mode::ZP))
  when 0x28 then plp
  when 0x29 then and_operation(get_address(Mode::IMM))
  when 0x2A then rol_accumulator
  when 0x2C then bit(get_address(Mode::ABS))
  when 0x2D then and_operation(get_address(Mode::ABS))
  when 0x2E then rol(get_address(Mode::ABS))
  when 0x30 then bmi
  when 0x31 then and_operation(get_address(Mode::IZY))
  when 0x35 then and_operation(get_address(Mode::ZPX))
  when 0x36 then rol(get_address(Mode::ZPX))
  when 0x38 then sec
  when 0x39 then and_operation(get_address(Mode::ABY))
  when 0x3D then and_operation(get_address(Mode::ABX))
  when 0x3E then rol(get_address(Mode::ABX))
  when 0x40 then rti
  when 0x41 then eor(get_address(Mode::IZX))
  when 0x45 then eor(get_address(Mode::ZP))
  when 0x46 then lsr(get_address(Mode::ZP))
  when 0x48 then pha
  when 0x49 then eor(get_address(Mode::IMM))
  when 0x4A then lsr_accumulator
  when 0x4C then jmp(get_address(Mode::ABS))
  when 0x4D then eor(get_address(Mode::ABS))
  when 0x4E then lsr(get_address(Mode::ABS))
  when 0x50 then bvc
  when 0x51 then eor(get_address(Mode::IZY))
  when 0x55 then eor(get_address(Mode::ZPX))
  when 0x56 then lsr(get_address(Mode::ZPX))
  when 0x58 then cli
  when 0x59 then eor(get_address(Mode::ABY))
  when 0x5D then eor(get_address(Mode::ABX))
  when 0x5E then lsr(get_address(Mode::ABX))
  when 0x60 then rts
  when 0x61 then adc(get_address(Mode::IZX))
  when 0x65 then adc(get_address(Mode::ZP))
  when 0x66 then ror(get_address(Mode::ZP))
  when 0x68 then pla
  when 0x69 then adc(get_address(Mode::IMM))
  when 0x6A then ror_accumulator
  when 0x6C then jmp(get_address(Mode::IND))
  when 0x6D then adc(get_address(Mode::ABS))
  when 0x6E then ror(get_address(Mode::ABS))
  when 0x70 then bvs
  when 0x71 then adc(get_address(Mode::IZY))
  when 0x75 then adc(get_address(Mode::ZPX))
  when 0x76 then ror(get_address(Mode::ZPX))
  when 0x78 then sei
  when 0x79 then adc(get_address(Mode::ABY))
  when 0x7D then adc(get_address(Mode::ABX))
  when 0x7E then ror(get_address(Mode::ABX))
  when 0x81 then sta(get_address(Mode::IZX))
  when 0x84 then sty(get_address(Mode::ZP))
  when 0x85 then sta(get_address(Mode::ZP))
  when 0x86 then stx(get_address(Mode::ZP)) # STX Zero Page
  when 0x88 then dey
  when 0x8A then txa
  when 0x8C then sty(get_address(Mode::ABS))
  when 0x8D then sta(get_address(Mode::ABS))
  when 0x8E then stx(get_address(Mode::ABS))
  when 0x90 then bcc
  when 0x91 then sta(get_address(Mode::IZY))
  when 0x94 then sty(get_address(Mode::ZPX))
  when 0x95 then sta(get_address(Mode::ZPX))
  when 0x96 then stx(get_address(Mode::ZPY)) # STX Zero Page, Y
  when 0x98 then tya
  when 0x99 then sta(get_address(Mode::ABY))
  when 0x9A then txs
  when 0x9D then sta(get_address(Mode::ABX))
  when 0xA0 then ldy(get_address(Mode::IMM))
  when 0xA1 then lda(get_address(Mode::IZX))
  when 0xA2 then ldx(get_address(Mode::IMM))
  when 0xA4 then ldy(get_address(Mode::ZP))
  when 0xA5 then lda(get_address(Mode::ZP))
  when 0xA6 then ldx(get_address(Mode::ZP))
  when 0xA8 then tay
  when 0xA9 then lda(get_address(Mode::IMM))
  when 0xAA then tax
  when 0xAC then ldy(get_address(Mode::ABS))
  when 0xAD then lda(get_address(Mode::ABS))
  when 0xAE then ldx(get_address(Mode::ABS))
  when 0xB0 then bcs
  when 0xB1 then lda(get_address(Mode::IZY))
  when 0xB4 then ldy(get_address(Mode::ZPX))
  when 0xB5 then lda(get_address(Mode::ZPX))
  when 0xB6 then ldx(get_address(Mode::ZPY))
  when 0xB8 then clv
  when 0xB9 then lda(get_address(Mode::ABY))
  when 0xBA then tsx
  when 0xBC then ldy(get_address(Mode::ABX))
  when 0xBD then lda(get_address(Mode::ABX))
  when 0xBE then ldx(get_address(Mode::ABY))
  when 0xC0 then cpy(get_address(Mode::IMM))
  when 0xC1 then cmp(get_address(Mode::IZX))
  when 0xC4 then cpy(get_address(Mode::ZP))
  when 0xC5 then cmp(get_address(Mode::ZP))
  when 0xC6 then dec(get_address(Mode::ZP))
  when 0xC8 then iny
  when 0xC9 then cmp(get_address(Mode::IMM))
  when 0xCA then dex
  when 0xCC then cpy(get_address(Mode::ABS))
  when 0xCD then cmp(get_address(Mode::ABS))
  when 0xCE then dec(get_address(Mode::ABS))
  when 0xD0 then bne
   # Compare with Accumulator (CMP) - Indexed Indirect
  when 0xD1 then cmp(get_address(Mode::INDX))
  # Omitted opcodes (0xD2-0xD4)
  # Compare with Accumulator (CMP) - Zero Page,X
  when 0xD5 then cmp(get_address(Mode::ZPX))
  # Decrement Memory - Zero Page,X
  when 0xD6 then dec(get_address(Mode::ZPX))
  # Omitted opcode (0xD7)
  # Clear Decimal Mode (CLD)
  when 0xD8 then cld
  # Compare with Accumulator (CMP) - Absolute,Y
  when 0xD9 then cmp(get_address(Mode::ABSY))
  # Omitted opcodes (0xDA-0xDB)
  # Compare with Accumulator (CMP) - Absolute,X
  when 0xDD then cmp(get_address(Mode::ABSX))
  # Decrement Memory - Absolute,X
  when 0xDE then dec(get_address(Mode::ABSX))
  # Omitted opcode (0xDF)
  # Compare with X Register (CPX) - Immediate
  when 0xE0 then cpx(get_address(Mode::IMM))
  # Subtract with Borrow (SBC) - Indexed Indirect
  when 0xE1 then sbc(get_address(Mode::INDX))
  # Omitted opcodes (0xE2-0xE4)
  # Subtract with Borrow (SBC) - Zero Page
  when 0xE5 then sbc(get_address(Mode::ZP))
  # Increment Memory - Zero Page
  when 0xE6 then inc(get_address(Mode::ZP))
  # Omitted opcode (0xE7)
  # Increment X Register (INX)
  when 0xE8 then inx
  # Subtract with Borrow (SBC) - Immediate
  when 0xE9 then sbc(get_address(Mode::IMM))
  # No Operation (NOP)
  when 0xEA then nop
  # Omitted opcode (0xEB)
  # Compare with X Register (CPX) - Absolute
  when 0xEC then cpx(get_address(Mode::ABS))
  # Subtract with Borrow (SBC) - Absolute
  when 0xED then sbc(get_address(Mode::ABS))
  # Increment Memory - Absolute
  when 0xEE then inc(get_address(Mode::ABS))
  # Omitted opcode (0xEF)
  # Branch if Overflow Set (BVS)
  when 0xF0 then bvs
  # Subtract with Borrow (SBC) - Indirect Indexed
  when 0xF1 then sbc(get_address(Mode::INDY))
  # Omitted opcodes (0xF2-0xF4)
  # Subtract with Borrow (SBC) - Zero Page,X
  when 0xF5 then sbc(get_address(Mode::ZPX))
  # Increment Memory - Zero Page,X
  when 0xF6 then inc(get_address(Mode::ZPX))
  # Omitted opcode (0xF7)
  # Set Decimal Flag (SED)
  when 0xF8 then sed
  # Subtract with Borrow (SBC) - Absolute,Y
  when 0xF9 then sbc(get_address(Mode::ABSY))
  # Omitted opcodes (0xFA-0xFB)
  # Subtract with Borrow (SBC) - Absolute,X
  when 0xFD then sbc(get_address(Mode::ABSX))
  # Increment Memory - Absolute,X
  when 0xFE then inc(get_address(Mode::ABSX))
  # Omitted opcode (0xFF)
  else
    raise "Unknown opcode: 0x#{opcode.to_s(16)}"
  end
end

    # Implement the CPU's main execution loop
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

def fetch_byte
  raise "Program counter (PC) out of range" if pc < 0x0000 || pc > 0xFFFF

  byte = memory[pc]
  pc += 1
  byte
rescue IndexError
  raise "Memory access out of bounds"
end

  # Utility method to fetch a 16-bit word from memory at the program counter (PC)
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
    # In absolute X-indexed addressing mode, the address is modified by adding the X register.
    # If the high byte (representing the page number) of the base address changes after adding X, a page boundary is crossed.
    base_address = fetch_word
    crossed = (base_address & 0xFF00) != ((base_address + @registers[:X]) & 0xFF00)
  when Mode::ABSY
    # Similar to ABSX, but the Y register is added to the base address.
    base_address = fetch_word
    crossed = (base_address & 0xFF00) != ((base_address + @registers[:Y]) & 0xFF00)
  when Mode::INDY
    # In indirect Y-indexed addressing mode, the effective address is obtained by reading a zero-page address and adding Y.
    # If adding Y changes the page of the effective address, a page boundary is crossed.
    zp_address = fetch_byte
    base_address = read_memory(zp_address) | (read_memory((zp_address + 1) & 0xFF) << 8)
    crossed = (base_address & 0xFF00) != ((base_address + @registers[:Y]) & 0xFF00)
  else
    # For other addressing modes, page boundary crossing is not applicable or does not affect cycle count.
    crossed = false
  end
  crossed
end

  def branch_taken?(instruction)
    return false unless instruction[:addr_mode] == Mode::REL

    offset = fetch_byte
    case instruction[:operation].name
    when :bpl
      @registers[:P] & Flags::NEGATIVE == 0
    when :bmi
      @registers[:P] & Flags::NEGATIVE != 0
    when :bvc
      @registers[:P] & Flags::OVERFLOW == 0
    when :bvs
      @registers[:P] & Flags::OVERFLOW != 0
    when :bcc
      @registers[:P] & Flags::CARRY == 0
    when :bcs
      @registers[:P] & Flags::CARRY != 0
    when :bne
      @registers[:P] & Flags::ZERO == 0
    when :beq
      @registers[:P] & Flags::ZERO != 0
    else
      false
    end
  end
end
