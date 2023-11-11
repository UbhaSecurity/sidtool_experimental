module Sidtool
  class State
    attr_accessor :current_frame
    attr_reader :sid6581
    attr_reader :cia_timers

    def initialize
      @current_frame = 0
      @sid6581 = Sid6581.new
      @cia_timers = [CIATimer.new(self), CIATimer.new(self)]
    end

    # Update the state for the current frame
    def update
      # Update CIA timers
      @cia_timers.each(&:update)

      # Check for and handle interrupts
      handle_interrupts

      # Update SID chip state, e.g., process sound generation for the current frame
      @sid6581.update

      # Advance to the next frame
      @current_frame += 1
    end

    private

    # Handle interrupts from CIA timers or other sources
    def handle_interrupts
      @cia_timers.each do |timer|
        if timer.underflow
          # Handle the specific actions to be taken on timer underflow
          # This could include triggering interrupts or other responses
        end
      end

      # Additional logic for other interrupt sources or state changes
    end

    # Additional methods related to state management can be added here
    # For example, methods to synchronize with other components, etc.
  end
end
