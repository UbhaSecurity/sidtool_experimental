module SidtoolExperimental
  class C64Emulator
    attr_reader :memory, :cpu, :sid, :state, :display, :keyboard

    def initialize
      @memory = Memory.new
      @cpu = Mos6510::Cpu.new(@memory)  # Correctly reference the @memory instance variable
      @sid = Sid6581.new
      @ciaTimerA = CIATimer.new(@cpu)
      @ciaTimerB = CIATimer.new(@cpu)
      @state = State.new
      @display = Display.new # Placeholder for display handling
      @keyboard = Keyboard.new # Placeholder for keyboard handling
    end

    def load_program(program_data, start_address)
      @cpu.load_program(program_data, start_address)
    end

    def run
      @cpu.reset
      until @state.emulation_finished?
        @cpu.step
        emulate_cycle
        @display.refresh if @display
        @keyboard.check_input if @keyboard
      end
    end

    def stop
      @state.emulation_finished = true
    end

    private

    def emulate_cycle
      @state.update
      @state.handle_interrupts
      @sid.generate_sound
    end

    def handle_sid_operations
      # Define SID address range
      sid_address_range = 0xD400..0xD7FF

      # Iterate through SID address range
      sid_address_range.each do |address|
        if @memory.io_area?(address)
          value = @memory.read_io(address)
          @sid.write_register(address, value)
        end
      end

      # Update SID state
      @sid.update_sid_state
    end

    def write_register(address, value)
      @sid.write_register(address, value)
    end

    def read_register(address)
      @sid.read_register(address)
    end
  end
end
