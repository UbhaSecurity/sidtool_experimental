module SidtoolExperimental
  class C64Emulator
    attr_reader :memory, :cpu, :ciaTimerA, :ciaTimerB
    attr_accessor :sid6581, :state

    def initialize(memory, sid6581)
      @memory = memory
      @cpu = Mos6510::Cpu.new(@memory, self)  # Initialize CPU with memory and self-reference
      @ciaTimerA = CIATimer.new(self)         # Initialize CIA Timer A
      @ciaTimerB = CIATimer.new(self)         # Initialize CIA Timer B
      @sid6581 = sid6581                      # SID chip instance
    end

def load_sid_file(file_path)
  sid_file = FileReader.read(file_path)
  
  # Debugging: Print the start address
  puts "Start Address: #{sid_file.load_address}"

  load_address = sid_file.load_address
  raise 'Memory not initialized' unless @memory.is_a?(Memory)
  raise 'Invalid start address' unless @memory.valid_address?(load_address)

  # Example fix: Pass both program data and the load address
  load_program(sid_file.data, load_address)

  setup_sid_environment(sid_file)
end

def load_program(program_data, start_address)
  # Validate the program data and start address
  raise 'Invalid program data' unless program_data.is_a?(Array)

  # Debugging: Print the start address
  puts "Loading program at start address: #{start_address.to_s(16)}"

  raise 'Invalid start address' unless @memory.valid_address?(start_address)

  # Debugging: Print the program data size
  puts "Program data size: #{program_data.size} bytes"

  @cpu.load_program(program_data, start_address)  # Load program into CPU
end

    def run
      @cpu.reset                                   # Reset CPU
      until @state.emulation_finished?            # Run until emulation is finished
        @cpu.step                                 # Execute CPU cycle
        emulate_cycle                             # Execute additional emulation cycle
      end
    end

    def stop
      @state.emulation_finished = true            # Flag to stop the emulation
    end

    def run_cycle    
      @cpu.step                                   # Execute a single CPU cycle
      emulate_cycle                               # Emulate additional cycle activities
    end

    private

    def emulate_cycle
      @state.update                               # Update state
      @sid6581.generate_sound                     # Generate SID sound
      @ciaTimerA.update                           # Update CIA Timer A
      @ciaTimerB.update                           # Update CIA Timer B
    end

    def setup_sid_environment(sid_file)
      @cpu.pc = sid_file.init_address             # Set CPU program counter

      if sid_file.version >= 2
        handle_extended_sid_file(sid_file)        # Handle extended SID features
      end
    end

    def handle_extended_sid_file(sid_file)
      # Implement extended SID features based on the SID file's specifications
    end

    # Implement additional methods for SID operations and memory management
  end
end
