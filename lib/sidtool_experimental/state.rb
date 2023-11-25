module SidtoolExperimental
  class State
    attr_accessor :current_frame, :emulation_finished, :memory
    attr_reader :sid6581, :cia_timers

    def initialize
      @current_frame = 0
      @memory = Memory.new  # Initialize memory
      @sid6581 = Sid6581.new(memory: @memory)  # Pass memory to SID
      @cia_timers = [CIATimer.new(self), CIATimer.new(self)]
      @emulation_finished = false
      @interrupt_flag = false # Flag to ignore or respond to IRQs
      initialize_vectors
    end

    def update
      update_timers
      handle_timer_events
      update_sid
      handle_interrupts
      increment_frame
    end

    def handle_interrupts
      handle_irq if irq_pending? && !@interrupt_flag
      handle_nmi if nmi_pending?
    end

    private

    def update_timers
      @cia_timers.each(&:update)
    end

def handle_timer_events
  # Loop through CIA timers
  @cia_timers.each_with_index do |timer, index|
    # Check if a specific timer event condition is met
    if timer.event_condition_met?
      # Perform actions specific to the event
      case index
      when 0
        # Timer 0 event handling
        # Example: Generate an interrupt
        generate_interrupt(:timer0)
      when 1
        # Timer 1 event handling
        # Example: Perform a task
        perform_task_for_timer1
      end
    end
  end
end

def update_sid
  @sid6581.update(@current_frame)
end

    def increment_frame
      @current_frame += 1
    end

    def initialize_vectors
      # Initialize IRQ, NMI, and BREAK vectors based on KERNAL ROM
      @irq_vector = 0xEA31
      @nmi_vector = 0xFE43
      @break_vector = 0xFE66
    end

    def handle_irq
      if irq_pending?
        # Save CPU state (registers, program counter, etc.)
        @cpu.save_state

        # Jump to the IRQ vector address and execute the IRQ routine
        @cpu.jump_to_address(@irq_vector)

        # The IRQ routine is responsible for acknowledging the IRQ
        # and performing necessary actions

        # Restore the CPU state after IRQ handling
        @cpu.restore_state
      end
    end

    def handle_nmi
      if nmi_pending?
        # Save CPU state (registers, program counter, etc.)
        @cpu.save_state

        # Jump to the NMI vector address and execute the NMI routine
        @cpu.jump_to_address(@nmi_vector)

        # The NMI routine typically checks the cause of the NMI and handles it
        # For example, it might handle the RUN/STOP + RESTORE keypress

        # Restore the CPU state after NMI handling
        @cpu.restore_state
      end
    end
  end
end
