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
  class Debug
    def self.run
      puts "Starting Debugging of Memory Class..."

      # Create an instance of the Memory class
      memory = Memory.new

      # Check RAM Initialization
      if memory.ram.size == 65536 && memory.ram.all? { |byte| byte == 0 }
        puts "RAM Initialization: PASS"
      else
        puts "RAM Initialization: FAIL"
      end

      # Check ROM Loading
      puts "BASIC ROM Loading: #{memory.basic_rom ? 'PASS' : 'FAIL'}"
      puts "KERNAL ROM Loading: #{memory.kernal_rom ? 'PASS' : 'FAIL'}"
      puts "Character ROM Loading: #{memory.char_rom ? 'PASS' : 'FAIL'}"

      # Check I/O Devices Initialization
      if memory.io_devices.is_a?(Hash) && memory.io_devices.keys.sort == [:cia1, :cia2, :sid, :vic]
        puts "I/O Devices Initialization: PASS"
      else
        puts "I/O Devices Initialization: FAIL"
      end

      # Check Default Memory Configuration
      defaults_pass = memory.loram == 1 && memory.hiram == 1 && 
                      memory.charen == 1 && memory.exrom == 0 &&
                      memory.game == 0 && memory.processor_port == 0x37
      puts "Default Memory Configuration: #{defaults_pass ? 'PASS' : 'FAIL'}"

      puts "Debugging Complete."
    end
  end
end

# Run the debug script
SidtoolExperimental::Debug.run
