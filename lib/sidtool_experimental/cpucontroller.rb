class CpuController
  # Accessors for CPU and memory objects
  attr_accessor :memory, :cpu

  # Initialize the CPU Controller
  # @param [Object] sid (optional) - SID chip or related object for sound emulation
  def initialize(sid: nil)
    # Initial setup of the controller, including the optional SID chip
  end

  # Load a program or bytes into memory
  # @param [Array<Integer>] bytes - The bytes (as an array) to load into memory
  # @param [Integer] from - The starting address in memory to load the bytes (default: 0)
  def load(bytes, from: 0)
    # Logic to load the bytes into memory starting from the specified address
  end

  # Set a byte in memory at a specified address
  # @param [Integer] addr - The memory address where the byte is to be set
  # @param [Integer] value - The byte value to set at the specified memory address
  def set_mem(addr, value)
    # Logic to set a single byte of memory at the specified address
  end

  # Increment the program counter
  def pc_increment
    # Logic for incrementing the program counter
  end

  # Read a byte from a specific address in memory
  # @param [Integer] address - The memory address from which to read the byte
  def read_memory(address)
    # Check if the address is valid before reading
    validate_address(address)
    # Return the byte from the specified address
    @memory[address]
  end

  # Write a byte to a specific address in memory
  # @param [Integer] address - The memory address where the byte will be written
  # @param [Integer] byte - The byte to write to the specified memory address
  def write_memory(address, byte)
    # Check if the address is valid before writing
    validate_address(address)
    # Write the byte to the specified address
    @memory[address] = byte
  end

  private

  # Validate a memory address
  # @param [Integer] address - The memory address to validate
  def validate_address(address)
    # Ensure that the address is within the valid range of 0x0000 to 0xFFFF
    unless address >= 0x0000 && address <= 0xFFFF
      raise "Invalid memory address: 0x#{address.to_s(16)}"
    end
  end
end
