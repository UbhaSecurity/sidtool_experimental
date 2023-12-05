module SidtoolExperimental
  class C64Emulator
    attr_reader :memory, :cpu, :sid6581, :ciaTimerA, :ciaTimerB, :state

    def initialize
      @memory = Memory.new
      @cpu = Mos6510::Cpu.new(@memory, self) # Ensure two arguments are passed
      @sid6581 = Sid6581.new(memory: @memory)
      @ciaTimerA = CIATimer.new(self)
      @ciaTimerB = CIATimer.new(self)
      @state = State.new(@cpu, self) # This should work now
    end

    def load_sid_file(file_path)
      sid_file = FileReader.read(file_path)

      # Ensure that @memory is an instance of the Memory class and is properly initialized
      raise 'Memory not initialized' unless @memory.is_a?(Memory)

      # Check if the start address is valid
      raise 'Invalid start address' unless @memory.valid_address?(sid_file.load_address)

      load_program(sid_file.data, sid_file.load_address)
      setup_sid_environment(sid_file)
    end

    def load_program(program_data, start_address)
      @cpu.load_program(program_data, start_address)
    end

    def run
      @cpu.reset
      until @state.emulation_finished?
        @cpu.step
        emulate_cycle
      end
    end

    def stop
      @state.emulation_finished = true
    end

    def run_cycle    
      @cpu.step
      emulate_cycle
    end

    private

    def emulate_cycle
      @state.update
      @sid6581.generate_sound
      # Add more logic as needed for the emulation cycle
    end

    def setup_sid_environment(sid_file)
      # Setup the environment based on the SID file's properties
      # Example setup (adjust as necessary):
      @cpu.pc = sid_file.init_address
      # More setup logic here if needed
    end

    # Additional methods for SID operations, memory management, etc.
  end
end
