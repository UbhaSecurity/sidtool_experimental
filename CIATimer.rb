module Sidtool
  class CIATimer
    # Constants for control register flags
    START_FLAG = 0x01
    ONESHOT_FLAG = 0x08
    # Other relevant flags and constants

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
      # Additional initialization as needed
    end

    # Update the timer, typically called each system clock cycle
    def update
      if running?
        @timer -= 1
        check_underflow
      end
      # Additional logic for timer control
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

    # Handle the timer underflow, such as triggering an interrupt
    def handle_underflow
      @underflow = true
      # Logic to handle underflow, e.g., triggering an interrupt
    end

    # Determine if the timer is running
    def running?
      (@control_register & START_FLAG) != 0
    end

    # Determine if the timer should reload after underflow
    def should_reload?
      !(@control_register & ONESHOT_FLAG != 0 && @underflow)
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
      # Additional logic for control register
    end

    # Additional methods as needed for timer functionality
  end
end
