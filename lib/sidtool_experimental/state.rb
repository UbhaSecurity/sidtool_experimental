module SidtoolExperimental
  class State
    attr_accessor :current_frame
    attr_reader :sid6581, :cia_timers

    def initialize
      @current_frame = 0
      @sid6581 = Sid6581.new
      @cia_timers = [CIATimer.new(self), CIATimer.new(self)]
    end

    def update
      update_timers
      handle_timer_events
      update_sid
      increment_frame
    end

    private

    def update_timers
      @cia_timers.each(&:update)
    end

    def handle_timer_events
      @cia_timers.each do |timer|
        if timer.underflow
          # Handle specific actions on timer underflow
        end
      end
    end

    def update_sid
      @sid6581.update(current_frame)
    end

    def increment_frame
      @current_frame += 1
    end
  end
end
