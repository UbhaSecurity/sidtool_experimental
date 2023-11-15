# Require necessary components for the Sidtool module.
require 'sidtool/version'

module Sidtool
  # Include various components of the Sidtool module.
  require 'sidtool/file_reader'
  require 'sidtool/ruby_file_writer'
  require 'sidtool/midi_file_writer'
  require 'sidtool/synth'
  require 'sidtool/voice'
  require 'sidtool/sid'
  require 'sidtool/state'
  require 'sidtool/cia_timer'
  require 'sidtool/sid_6581'
  require 'mos6510'

  # Define constants for PAL properties.
  # FRAMES_PER_SECOND sets the frame rate for the emulation, specific to the PAL system.
  # CLOCK_FREQUENCY sets the clock frequency of the SID chip in the PAL system.
  FRAMES_PER_SECOND = 50.0
  CLOCK_FREQUENCY = 985248.0

  # Constants for slide detection and handling in the emulation.
  # SLIDE_THRESHOLD and SLIDE_DURATION_FRAMES can be adjusted as needed for specific emulation requirements.
  SLIDE_THRESHOLD = 60
  SLIDE_DURATION_FRAMES = 20

  # Create a global state object for managing the overall state of the SID emulation.
  STATE = State.new

  # SidWrapper class to interface with the SID chip and CIA timers.
  class SidWrapper
    # Initialize the SidWrapper with a SID6581 object and two CIATimer instances.
    def initialize
      @sid6581 = Sid6581.new
      @ciaTimerA = CIATimer.new(STATE)
      @ciaTimerB = CIATimer.new(STATE)
    end

    # Method to write values to the SID chip's registers.
    # Handles specific address ranges for the SID chip.
    def poke(address, value)
      case address
      when 0xD400..0xD41C
        @sid6581.write_register(address, value)
      else
        # Additional handling for other address ranges, if necessary.
      end
    end

    # Method to emulate a single cycle of the SID chip.
    # Updates CIA timers and generates sound for the current cycle.
    def emulate_cycle
      @ciaTimerA.update
      @ciaTimerB.update
      @sid6581.generate_sound
    end
  end

  # Class method to initialize SID chip emulation.
  # Sets up the SidWrapper and Mos6510 CPU for the emulation process.
  def self.initialize_sid_emulation
    @sid_wrapper = SidWrapper.new
    @cpu = Mos6510::Cpu.new(sid: @sid_wrapper)
  end

  # Class method to run the emulation loop.
  # Continuously emulates SID cycles, can include additional logic for the emulation process.
  def self.emulate
    loop do
      @sid_wrapper.emulate_cycle
      # Place for additional logic for the emulation loop, if required.
    end
  end
end

# Initialize the SID emulation setup by calling the class method.
Sidtool.initialize_sid_emulation
