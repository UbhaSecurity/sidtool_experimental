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

      # Check if the start address is valid before proceeding
      raise 'Invalid start address' unless @memory.valid_address?(sid_file.load_address)

      load_program(sid_file.data, sid_file.load_address)
      setup_sid_environment(sid_file)
    end

    def load_program(program_data, start_address)
      raise 'Invalid program data' unless program_data.is_a?(Array)
      raise 'Invalid start address' unless @memory.valid_address?(start_address)

      program_data.each_with_index do |byte, offset|
        @memory.write(start_address + offset, byte)
      end
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

    def setup_sid_environment(sid_file)
      # Setup the environment based on the SID file's properties
      @cpu.pc = sid_file.init_address
      # Additional setup as needed
    end

    def emulate_cycle
      @state.update
      @sid6581.generate_sound
      # Add more logic as needed
    end

    # Additional methods for SID operations, memory management, etc.
  end
end
