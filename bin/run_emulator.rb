require_relative '../lib/sidtool_experimental/filereader'
require_relative '../lib/sidtool_experimental/midi_file_writer'
require_relative '../lib/sidtool_experimental/Sid6581'
require_relative '../lib/sidtool_experimental/synth'
require_relative '../lib/sidtool_experimental/voice'
require_relative '../lib/sidtool_experimental/version'
require_relative '../lib/sidtool_experimental/C64Emulator'
require_relative '../lib/sidtool_experimental/memory'
require_relative '../lib/sidtool_experimental/CIATimer'
require_relative '../lib/sidtool_experimental/RubyFileWriter'
require_relative '../lib/sidtool_experimental/state'
require_relative '../lib/sidtool_experimental/Mos6510'

module SidtoolExperimental
  class TestC64
    def initialize
      @memory = Memory.new  # Initialize the complex memory system
      @cpu = Mos6510::Cpu.new(@memory)  # Initialize the CPU with the memory system
      # Initialize other components as needed...
    end

    def run
      # Code to start and run the emulator goes here
      # For instance, this could include a loop to execute CPU cycles,
      # render graphics, process user input, etc.
    end
  end
end

# Main execution
test_c64 = SidtoolExperimental::TestC64.new
test_c64.run
