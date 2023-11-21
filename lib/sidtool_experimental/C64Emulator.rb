module SidtoolExperimental
  class C64Emulator
    def initialize
      @memory = Memory.new
      @cpu = Mos6510::Cpu.new(@memory)
      @sid = Sid6581.new
      @synth = Synth.new(0)
      @voice = Voice.new(@sid, 0)
      @state = State.new
      @display = Display.new # Placeholder for display handling (VIC-II chip)
      @keyboard = Keyboard.new # Placeholder for keyboard handling
    end

    def load_program(program_data, start_address)
      @cpu.load_program(program_data, start_address)
    end

    def run
      @cpu.reset
      until @state.emulation_finished?
        @cpu.step # Execute a single CPU instruction
        handle_sid_operations # Handle SID chip operations
        
        # Update other components
        @display.refresh if @display
        @keyboard.check_input if @keyboard

        @state.update # Update the emulator state
      end
    end

    def stop
      @state.emulation_finished = true
    end

    private

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
  end
end
