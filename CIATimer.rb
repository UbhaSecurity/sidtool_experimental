module Sidtool
  class CIATimer
    # Constants for control register flags
    START_FLAG = 0x01       # Timer start/stop
    ONESHOT_FLAG = 0x08     # One-shot mode
    PHASE_FLAG = 0x10       # Timer counts system clocks (PHI2) or underflows from other timer
    TOGGLE_FLAG = 0x40      # Timer output toggles between high and low on underflow
    INTERRUPT_FLAG = 0x80   # Enable interrupt on timer underflow

    attr_accessor :timer, :latch, :control_register, :underflow, :output_pin

    def initialize(cpu)
      reset
      @cpu = cpu  # CPU instance for triggering interrupts
      @output_pin = false  # State of the timer's output pin
    end

    # Reset the timer to its default state
    def reset
      @timer = 0xFFFF
      @latch = 0xFFFF
      @control_register = 0
      @underflow = false
      @output_pin = false
    end

    # Update the timer, typically called each system clock cycle
    def update
      if running?
        decrement_timer
        check_underflow
      end
    end

    # Decrement the timer
    def decrement_timer
      if (@control_register & PHASE_FLAG) != 0
        @timer -= 1 if @timer > 0
      else
        decrement_on_external_event if external_event_occurred?
      end
    end

    # Handle the timer underflow, such as triggering an interrupt
    def handle_underflow
      @underflow = true
      toggle_output if (@control_register & TOGGLE_FLAG) != 0
      trigger_interrupt if (@control_register & INTERRUPT_FLAG) != 0
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

    # Toggle the output pin state
    def toggle_output
      @output_pin = !@output_pin
    end

    # Trigger an interrupt via the CPU
    def trigger_interrupt
      @cpu.trigger_interrupt(:cia_timer_underflow)
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

    private

    # Logic to decrement the timer based on external events
    def decrement_on_external_event
      # Implement external event logic
    end

    # Logic to determine if an external event occurred
    def external_event_occurred?
      # Implement external event check
    end
  end
end
