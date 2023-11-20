class Memory
  def initialize
    @ram = Array.new(65536, 0)  # 64KB of RAM
    @rom = load_roms             # Load ROM data
    @io_registers = initialize_io_registers # Initialize I/O registers
  end

  def read(address)
    case address
    when 0xA000..0xBFFF
      rom_is_mapped(address) ? @rom['BASIC'][address - 0xA000] : @ram[address]
    when 0xD000..0xDFFF
      io_area?(address) ? read_io(address) : @rom['CHAR'][address - 0xD000]
    when 0xE000..0xFFFF
      @rom['KERNAL'][address - 0xE000]
    else
      @ram[address]
    end
  end

  def write(address, value)
    case address
    when 0xA000..0xBFFF, 0xE000..0xFFFF
      @ram[address] = value unless rom_is_mapped(address)
    when 0xD000..0xDFFF
      write_io(address, value) if io_area?(address)
    else
      @ram[address] = value
    end
  end

  # Load ROM data from binary files
  def load_roms
    rom_data = {}

    # Load BASIC ROM from a binary file
    basic_rom_filename = 'basic.rom'  # Replace with the actual filename
    rom_data['BASIC'] = File.binread(basic_rom_filename)

    # Load KERNAL ROM from a binary file
    kernal_rom_filename = 'kernal.rom'  # Replace with the actual filename
    rom_data['KERNAL'] = File.binread(kernal_rom_filename)

    # Load Character ROM from a binary file
    character_rom_filename = 'character.rom'  # Replace with the actual filename
    rom_data['CHAR'] = File.binread(character_rom_filename)

    rom_data
  end

  # Initialize I/O registers
  def initialize_io_registers
    # Initialize VIC-II, SID, CIA registers here
  end

  # Check if the ROM is mapped at the address
  def rom_is_mapped(address)
    # Add logic based on PLA state
  end

  # Check if address is in I/O area
  def io_area?(address)
    (0xD000..0xDFFF).include?(address)
  end

  # Read from I/O registers
  def read_io(address)
    # Add logic to handle I/O reads
  end

  # Write to I/O registers
  def write_io(address, value)
    # Add logic to handle I/O writes
  end
end
