module SidtoolExperimental
  class TestC64
    def initialize
      @emulator = C64Emulator.new  # Create a new instance of the C64 emulator
      load_basic_program
    end

    private

    def load_basic_program
      # BASIC code for "Hello World"
      basic_code = "10 PRINT \"HELLO WORLD\":REM"

      # Convert the BASIC code to a byte array suitable for the C64 memory
      basic_bytes = basic_code.bytes

      # Load the BASIC program into the C64 memory
      # We'll start at a typical BASIC start address. Adjust as needed.
      start_address = 0x0801
      basic_bytes.each_with_index do |byte, index|
        @emulator.memory.write(start_address + index, byte)
      end

      # End the program with a 0 byte (null terminator for BASIC programs)
      @emulator.memory.write(start_address + basic_bytes.length, 0)
    end

    public

    def run
      # Run the emulator
      @emulator.run
    end
  end
end

# Usage:
test_c64 = SidtoolExperimental::TestC64.new
test_c64.run
