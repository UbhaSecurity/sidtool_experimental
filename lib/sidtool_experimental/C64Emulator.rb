module SidtoolExperimental
  class C64Emulator
    attr_reader :memory, :cpu, :sid6581, :ciaTimerA, :ciaTimerB, :state

    def initialize
      @memory = Memory.new  # Instantiate Memory first
      @cpu = Mos6510::Cpu.new(@memory)  # Then instantiate CPU with Memory instance
      @sid6581 = Sid6581.new(memory: @memory)
      @ciaTimerA = CIATimer.new(self)
      @ciaTimerB = CIATimer.new(self)
      @state = State.new(@cpu)  # Pass CPU instance to State
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

    private

    def emulate_cycle
      @state.update
      @sid6581.generate_sound
      # Add more logic as needed
    end

    # Additional methods for SID operations, memory management, etc.
  end
end
