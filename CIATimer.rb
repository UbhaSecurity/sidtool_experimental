module Sidtool
  class CIATimer
    START_FLAG = 0x01       # Timer start/stop
    ONESHOT_FLAG = 0x08     # One-shot mode
    PHASE_FLAG = 0x10       # Timer counts system clocks (PHI2) or underflows from other timer
    TOGGLE_FLAG = 0x40      # Timer output toggles between high and low on underflow
    INTERRUPT_FLAG = 0x80   # Enable interrupt on timer underflow

    attr_accessor :timer, :latch, :control_register, :underflow

    def initialize
      reset
    end

    # Reset the timer to its default state
    def reset
      @timer = 0xFFFF
      @latch = 0xFFFF
      @control_register = 0
      @underflow = false
    end

    # Update the timer, typically called each system clock cycle
    def update
      if running?
        decrement_timer
        check_underflow
      end
    end

    # Check for timer underflow and handle accordingly
    def check_underflow
      if @timer == 0
        handle_underflow
        reload_timer if should_reload?
      end
    end

    # Reload the timer from the latch
    def reload_timer
      @timer = @latch
    end

    def decrement_timer
      if (@control_register & PHASE_FLAG) != 0
        @timer -= 1 if @timer > 0
      else
        # Logic to decrement based on external events or other timer's underflow
      end
    end

    # Handle the timer underflow, such as triggering an interrupt
    def handle_underflow
      @underflow = true
      toggle_output if (@control_register & TOGGLE_FLAG) != 0
      trigger_interrupt if (@control_register & INTERRUPT_FLAG) != 0
    end

    def toggle_output
      # Logic to toggle timer output
    end

    def trigger_interrupt
      # Logic to trigger an interrupt
    end

    # Determine if the timer is running
    def running?
      (@control_register & START_FLAG) != 0
    end

    # Determine if the timer should reload after underflow
    def should_reload?
      (@control_register & ONESHOT_FLAG) == 0 || !@underflow
    end

    # Set the low byte of the timer latch
    def set_latch_lo(value)
      @latch = (@latch & 0xFF00) | value
    end

    # Set the high byte of the timer latch
    def set_latch_hi(value)
      @latch = (@latch & 0x00FF) | (value << 8)
    end

    # Set the control register
    def set_control_register(value)
      @control_register = value
    end

    # Additional methods as needed for timer functionality
    # ...
  end
end
