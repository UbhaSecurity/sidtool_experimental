module SidtoolExperimental
  class Sid
    attr_reader :sid6581, :ciaTimerA, :ciaTimerB

    # Initialize SID chip with CIA timers and voices
    def initialize
      @sid6581 = Sid6581.new
      @ciaTimerA = CIATimer.new(self)
      @ciaTimerB = CIATimer.new(self)
    end

    # Method to handle SID register writes
    def write_register(address, value)
      @sid6581.write_register(address, value)
    end

    # Method to handle SID register reads
    def read_register(address)
      @sid6581.read_register(address)
    end

    # Emulate SID chip for one cycle
    def emulate_cycle
      # The State class will now handle updates for CIA timers
      STATE.update

      # Since State manages the overall state, including interrupts,
      # we delegate interrupt handling to the State class.
      STATE.handle_interrupts

      @sid6581.generate_sound
    end
  end
end
