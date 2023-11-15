module Sidtool
  class State
    # Accessors for the current frame and readers for SID and CIA timers.
    # The current frame represents the current time step in the emulation.
    attr_accessor :current_frame
    attr_reader :sid6581
    attr_reader :cia_timers

    # Initialize the state with default values.
    # This includes setting the current frame to zero, initializing the SID6581 object for SID emulation,
    # and creating two CIA timers for managing timing-related functions.
    def initialize
      @current_frame = 0
      @sid6581 = Sid6581.new
      @cia_timers = [CIATimer.new(self), CIATimer.new(self)]
    end

    # Update the state for the current frame.
    # This method advances the emulation by one frame, updating timers, handling interrupts,
    # and updating the SID chip's state.
    def update
      # Update each CIA timer.
      @cia_timers.each(&:update)

      # Handle any interrupts that might have occurred, which could affect the SID's state or other emulation aspects.
      handle_interrupts

      # Update the state of the SID6581 chip, typically involving sound generation or processing for the current frame.
      @sid6581.update

      # Increment the current frame, advancing the emulation time.
      @current_frame += 1
    end

    private

    # Handle interrupts from CIA timers or other sources.
    # This private method is responsible for managing any interrupts or special conditions
    # that arise, particularly those related to timer underflows.
    def handle_interrupts
      @cia_timers.each do |timer|
        if timer.underflow
          # Specific actions to be taken on timer underflow, such as triggering interrupts,
          # updating states, or other responses specific to the emulation context.
        end
      end

      # Additional logic for handling interrupts from other sources or complex state changes can be placed here.
    end

    # Additional methods related to state management can be added here.
    # For example, methods for synchronizing with external components, handling user input, etc.
  end
end
