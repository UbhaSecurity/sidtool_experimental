module SidtoolExperimental
  class State
    attr_accessor :current_frame, :emulation_finished, :memory
    attr_reader :sid6581, :cia_timers, :cpu

    def initialize(cpu, emulator, cia_timers, sid6581)
      @cpu = cpu
      @emulator = emulator
      @memory = Memory.new
      @cia_timers = cia_timers || []
      @sid6581 = Sid6581.new(memory: @memory)
      @emulation_finished = false
      @interrupt_flag = false
      @current_frame = 0
      initialize_vectors
    end

    def update
      update_timers
      @cpu.handle_timer_interrupts
      handle_timer_events
      update_sid
      handle_interrupts
    end

    def read_sid_register(address)
      @sid6581.read_sid_register(address)
    end

    def write_sid_register(address, value)
      @sid6581.write_register(address, value)
    end

    def process_audio(sample_rate)
      audio_samples = @sid6581.process_audio(sample_rate)

      # Additional audio processing can be done here if needed

      return audio_samples
    end

    def handle_interrupts
      # Call irq_pending? and nmi_pending? on the @cpu instance
      handle_irq if @cpu.irq_pending? && !@interrupt_flag
      handle_nmi if @cpu.nmi_pending?
    end

    def generate_interrupt(source)
      case source
      when :timer0
        @cpu.set_irq_flag
      # Add more cases for other interrupt sources if needed
      end
    end

    def perform_task_for_timer1
      if timer1_condition_met?
        puts "Timer 1 event occurred. Performing a task..."
      end
    end

    def timer1_condition_met?
      @cia_timers[1].counter == specific_value
    end

    def handle_timer_0_expiration
      if timer_0_irq_enabled?
        @cpu.generate_interrupt(:irq)
      end
      # Other actions can be added here as needed
    end

    def handle_timer_1_expiration
      perform_specific_action_for_timer1
      # Any other logic that needs to be executed when Timer 1 expires
    end

    private

    def update_timers
      puts "Updating timers: #{@cia_timers}"
      @cia_timers.each { |timer| timer.update if timer }
    end

    def handle_timer_events
    end

    def update_sid
      @sid6581.update_sid_state
    end

    def increment_frame
      @current_frame += 1
    end

    def initialize_vectors
      @irq_vector = 0xEA31
      @nmi_vector = 0xFE43
      @break_vector = 0xFE66
    end

    def timer_0_irq_enabled?
      # Check the specific register or flag that controls IRQ for Timer 0
    end

    def perform_specific_action_for_timer1
      # Implement the specific action or task for Timer 1
    end

    # Modify the handle_irq method to use @cpu for handling IRQs
    def handle_irq
      if @cpu.irq_pending? && !@interrupt_flag
        @cpu.save_state
        @cpu.jump_to_address(@irq_vector)
        @cpu.restore_state
      end
    end

    # Modify the handle_nmi method to use @cpu for handling NMIs
    def handle_nmi
      if @cpu.nmi_pending?
        @cpu.save_state
        @cpu.jump_to_address(@nmi_vector)
        @cpu.restore_state
      end
    end    
  end
end
