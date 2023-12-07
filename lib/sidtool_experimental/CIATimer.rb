module SidtoolExperimental
    class CIATimer
    # Constants for Timer Modes
    ONE_SHOT_MODE = 1
    CONTINUOUS_MODE = 2
    INTERRUPT_ENABLE_FLAG = 0b00000001
    TIMER_MODE_FLAG = 0b00000010

    # Initializer
    def initialize

      @parallel_ports = Array.new(2) { {data: 0, direction: 0xFF} }
      @serial_shift_register = 0
    @timers = Array.new(2) do
      {
        counter: 0,
        mode: CONTINUOUS_MODE,
        control: 0,
        initial_value: 0,
        underflow: false
      }
    end
      @tod_clock = {hours: 0x12, minutes: 0, seconds: 0, tenths: 0, alarm_set: false, alarm_time: {}}
    end
    # Timer control methods
    def enable_interrupt(timer_index)
      @timers[timer_index][:control] |= INTERRUPT_ENABLE_FLAG
    end

    def disable_interrupt(timer_index)
      @timers[timer_index][:control] &= ~INTERRUPT_ENABLE_FLAG
    end

    def set_timer_mode(timer_index, mode)
      case mode
      when CONTINUOUS_MODE
        @timers[timer_index][:control] |= TIMER_MODE_FLAG
      when ONE_SHOT_MODE
        @timers[timer_index][:control] &= ~TIMER_MODE_FLAG
      end
    end

    def set_initial_value(timer_index, value)
      @timers[timer_index][:initial_value] = value
    end

    def underflow?(timer_index)
      @timers[timer_index][:underflow]
    end

    def interrupt_enabled?(timer_index)
      (@timers[timer_index][:control] & INTERRUPT_ENABLE_FLAG) != 0
    end

    def timer_mode_continuous?(timer_index)
      (@timers[timer_index][:control] & TIMER_MODE_FLAG) != 0
    end

    def clear_underflow(timer_index)
      @timers[timer_index][:underflow] = false
    end

    # Parallel I/O Management
    def set_data_direction(port, direction_mask)
      @parallel_ports[port][:direction] = direction_mask
    end

    def write_io_port(port, data)
      @parallel_ports[port][:data] = data
    end

    def read_io_port(port)
      @parallel_ports[port][:data] & @parallel_ports[port][:direction]
    end

    # Serial I/O Handling
    def write_to_shift_register(value)
      @serial_shift_register = value
    end

    def read_from_shift_register
      @serial_shift_register
    end

    def handle_serial_transfer
      # Implement logic for handling serial data transfer
    end

    # Timer Handling
    def configure_timer(timer_number, mode, value)
      set_timer_mode(timer_number, mode)
      set_initial_value(timer_number, value)
      @timers[timer_number][:counter] = value
    end

    # TOD Clock Handling
    def set_time(hours, minutes, seconds, tenths)
      @tod_clock[:hours] = hours
      @tod_clock[:minutes] = minutes
      @tod_clock[:seconds] = seconds
      @tod_clock[:tenths] = tenths
    end

    def read_time
      @tod_clock
    end

    def set_alarm_time(hours, minutes, seconds, tenths)
      @tod_clock[:alarm_set] = true
      @tod_clock[:alarm_time] = {hours: hours, minutes: minutes, seconds: seconds, tenths: tenths}
    end

    def check_alarm
      # Logic to check if the current time matches the alarm time
    end

    # Update method called each cycle
    def update
      update_timers
      check_alarm
      handle_serial_transfer
      # Additional update logic
    end

    def handle_timer_expiration(timer_index)
      case timer_index
      when 0
        # Handle Timer 0 expiration event
        @state.handle_timer_0_expiration
      when 1
        # Handle Timer 1 expiration event
        @state.handle_timer_1_expiration
      end
    end

    private

   def update_timers
  @timers.each do |timer|
    next unless timer_active?(timer)

    # Decrement the timer counter if it's active
    timer[:counter] -= 1

    # Check for underflow
    if timer[:counter] <= 0
      handle_underflow(timer)
    end
  end
end

def timer_active?(timer)
  timer[:control] & TIMER_MODE_FLAG != 0
end

def handle_underflow(timer)
  # Set underflow flag
  timer[:underflow] = true

  # Reload the timer if in continuous mode
  timer[:counter] = timer[:initial_value] if timer_mode_continuous?(timer)

  # Trigger an interrupt if enabled
  @state.generate_interrupt(:timer) if interrupt_enabled?(timer)
end

  end
end
