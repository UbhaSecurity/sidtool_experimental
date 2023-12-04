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
      puts "Memory initialized: #{@memory != nil}"  # Debugging statement

      # Check if memory responds to expected methods (additional debugging)
      if @memory.respond_to?(:[]) && @memory.respond_to?(:[]=)
        puts "Memory object is valid and ready."
      else
        puts "Memory object is not valid. Please check Memory class implementation."
      end

      @cpu = Mos6510::Cpu.new(@memory)  # Initialize the CPU with the memory system
      puts "CPU initialized with memory."  # Debugging statement
    end

    def run
      # Implementation for running the emulator...
    end
  end
end
