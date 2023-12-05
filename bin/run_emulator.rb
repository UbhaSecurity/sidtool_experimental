require 'optparse'
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
    def initialize(sid_file_path)
      puts "Initializing TestC64 with SID file: #{sid_file_path}"

      @memory = Memory.new
      @sid6581 = Sid6581.new(memory: @memory)
      @c64_emulator = C64Emulator.new(@memory, @sid6581)
      @sid_file_path = sid_file_path

      puts "TestC64 initialization complete."
    end

    def run
      puts "Running the emulator..."
      begin
        @c64_emulator.load_sid_file(@sid_file_path)
        @c64_emulator.run
      rescue StandardError => e
        puts "Error during SID file loading or emulation: #{e.message}"
        puts e.backtrace.join("\n")
      end
    end
  end
end

# Main execution
if ARGV.empty?
  puts "Please provide a SID file path."
  exit
end

sid_file_path = ARGV[0]
begin
  test_c64 = SidtoolExperimental::TestC64.new(sid_file_path)
  test_c64.run
rescue StandardError => e
  puts "Error occurred: #{e.message}"
  puts e.backtrace.join("\n")
end
