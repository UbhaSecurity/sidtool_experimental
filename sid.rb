module Sidtool
  class Sid
    # Initialize SID chip with CIA timers and voices
    def initialize
      @sid6581 = Sid6581.new
      @ciaTimerA = CIATimer.new(self)
      @ciaTimerB = CIATimer.new(self)
    end

    # Method to handle SID register writes
    def write_register(address, value)
      # Pass writes to SID 6581
      @sid6581.write_register(address, value)
    end

    # Method to handle SID register reads
    def read_register(address)
      # Read from SID 6581
      @sid6581.read_register(address)
    end

    # Emulate SID chip for one cycle
    def emulate_cycle
      # Update timers
      @ciaTimerA.update
      @ciaTimerB.update

      # Check for interrupts and handle them
      handle_interrupts

      # Generate SID sound for this cycle
      @sid6581.generate_sound
    end

    private

    def handle_interrupts
      # Check each CIA timer for underflow and handle accordingly
      if @ciaTimerA.underflow
        # Handle underflow for CIA Timer A (e.g., update SID state or trigger actions)
        # ...
      end

      if @ciaTimerB.underflow
        # Handle underflow for CIA Timer B
        # ...
      end

      # Additional logic for handling interrupts from other sources if necessary
      # ...
    end
  end
end
