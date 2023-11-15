module Sidtool
  class Sid
    # Initialize SID chip with CIA timers and voices
    # The initialize method sets up the SID emulation environment. It creates an instance of the Sid6581 class,
    # representing the SID chip model, and two instances of the CIATimer class for handling timing operations.
    def initialize
      @sid6581 = Sid6581.new
      @ciaTimerA = CIATimer.new(self)
      @ciaTimerB = CIATimer.new(self)
    end

    # Method to handle SID register writes
    # This method delegates the operation of writing to SID registers to the @sid6581 object, 
    # encapsulating the low-level register manipulation.
    def write_register(address, value)
      @sid6581.write_register(address, value)
    end

    # Method to handle SID register reads
    # Similar to write_register, this method delegates the reading of SID registers to the @sid6581 object,
    # ensuring encapsulation of register access logic.
    def read_register(address)
      @sid6581.read_register(address)
    end

    # Emulate SID chip for one cycle
    # The emulate_cycle method represents a single cycle of SID chip emulation. It updates CIA timers,
    # handles interrupts, and generates SID sound for the current cycle. This method is central to the SID's
    # sound production and timing control.
    def emulate_cycle
      @ciaTimerA.update
      @ciaTimerB.update

      handle_interrupts

      @sid6581.generate_sound
    end

    private

    # Handle interrupts and timer underflows
    # This private method manages interrupts, particularly checking for underflow conditions in CIA timers.
    # It handles any necessary actions or state updates that occur as a result of these interrupts.
    def handle_interrupts
      if @ciaTimerA.underflow
        # Logic for handling underflow for CIA Timer A
      end

      if @ciaTimerB.underflow
        # Logic for handling underflow for CIA Timer B
      end

      # Additional logic for handling other interrupts can be added here
    end
  end
end
