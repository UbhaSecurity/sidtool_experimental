# Require necessary components for the Sidtool module.
require 'sidtool/version'
require 'sidtool/file_reader'
require 'sidtool/ruby_file_writer'
require 'sidtool/midi_file_writer'
require 'sidtool/synth'
require 'sidtool/voice'
require 'sidtool/sid'
require 'sidtool/state' # This now includes the CIATimer class as well
require 'sidtool/sid_6581'
require 'mos6510'

module Sidtool
  # Define constants for PAL properties.
  FRAMES_PER_SECOND = 50.0
  CLOCK_FREQUENCY = 985248.0

  # Constants for slide detection and handling in the emulation.
  SLIDE_THRESHOLD = 60
  SLIDE_DURATION_FRAMES = 20

  # Create a global state object for managing the overall state of the SID emulation.
  STATE = State.new

  # SidWrapper class to interface with the SID chip and CIA timers.
  class SidWrapper
    attr_reader :sid6581, :ciaTimerA, :ciaTimerB

    def initialize
      @sid6581 = Sid6581.new
      @ciaTimerA = CIATimer.new(STATE)
      @ciaTimerB = CIATimer.new(STATE)
    end

    def poke(address, value)
      case address
      when 0xD400..0xD41C
        @sid6581.write_register(address, value)
      else
        # Additional handling for other address ranges, if necessary.
      end
    end

    def emulate_cycle
      STATE.update
      @sid6581.generate_sound
    end
  end

  # Class method to initialize SID chip emulation.
  def self.initialize_sid_emulation
    @sid_wrapper = SidWrapper.new
    @cpu = Mos6510::Cpu.new(sid: @sid_wrapper)
  end

  # Class method to run the emulation loop.
  def self.emulate
    loop do
      @sid_wrapper.emulate_cycle
      # Additional logic for the emulation loop, if required.
    end
  end
end

# Initialize the SID emulation setup by calling the class method.
Sidtool.initialize_sid_emulation