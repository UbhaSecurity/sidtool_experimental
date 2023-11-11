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
      @cpu = cpu  # CPU instance for triggering interrupts
      reset
    end

    def reset
      @timer = 0xFFFF
      @latch = 0xFFFF
      @control_register = 0
      @underflow = false
      @output_pin = false
    end

    def update
      if running?
        decrement_timer
        check_underflow
      end
    end

    def decrement_timer
      if (@control_register & PHASE_FLAG) != 0
        @timer -= 1 if @timer > 0
      else
        decrement_on_external_event if external_event_occurred?
      end
    end

    def handle_underflow
      @underflow = true
      toggle_output if (@control_register & TOGGLE_FLAG) != 0
      trigger_interrupt if (@control_register & INTERRUPT_FLAG) != 0
    end

    def check_underflow
      if @timer == 0
        handle_underflow
        reload_timer if should_reload?
      end
    end

    def reload_timer
      @timer = @latch
    end

    def toggle_output
      @output_pin = !@output_pin
    end

    def trigger_interrupt
      @cpu.trigger_interrupt(:cia_timer_underflow)
    end

    def running?
      (@control_register & START_FLAG) != 0
    end

    def should_reload?
      (@control_register & ONESHOT_FLAG) == 0 || !@underflow
    end

    def set_latch_lo(value)
      @latch = (@latch & 0xFF00) | value
    end

    def set_latch_hi(value)
      @latch = (@latch & 0x00FF) | (value << 8)
    end

    def set_control_register(value)
      @control_register = value
    end

    private

    def decrement_on_external_event
      # Logic for decrementing the timer based on external events
      # This could be based on other timers' underflows or other external triggers
    end

    def external_event_occurred?
      # Determine if an external event has occurred
      # This could involve checking the state of other components or external triggers
    end
  end
end

