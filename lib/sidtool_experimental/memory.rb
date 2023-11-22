class Memory
  attr_accessor :ram, :basic_rom, :kernal_rom, :char_rom, :io_devices
  attr_accessor :loram, :hiram, :charen, :exrom, :game

  def initialize
    @ram = Array.new(65536, 0) # 64KB of RAM
    @basic_rom = load_rom('basic.rom') # Load BASIC ROM
    @kernal_rom = load_rom('kernal.rom') # Load KERNAL ROM
    @char_rom = load_rom('char.rom') # Load Character ROM
    @io_devices = setup_io_devices # Setup I/O devices (VIC, SID, CIA)

    # Memory management attributes
    @loram = @hiram = @charen = 1 # Defaults to 1 on reset
    @exrom = @game = 0            # Defaults to 0 (no cartridge)
  end

  def read(address)
    case address
    when 0xA000..0xBFFF
      rom_area_basic(address)
    when 0xD000..0xDFFF
      io_or_char_rom(address)
    when 0xE000..0xFFFF
      rom_area_kernal(address)
    else
      @ram[address]
    end
  end

  def write(address, value)
    case address
    when 0xD000..0xDFFF
      write_io_or_char_rom(address, value)
    else
      @ram[address] = value
    end
  end

  private

  def rom_area_basic(address)
    return @basic_rom[address - 0xA000] if @loram == 1 && @hiram == 1 && @exrom == 0
    @ram[address]
  end

  def io_or_char_rom(address)
    if @charen == 1 && @hiram == 1 && @exrom == 0
      return @io_devices.read_io(address)
    elsif @charen == 0
      return @char_rom[address - 0xD000]
    end
    @ram[address]
  end

  def rom_area_kernal(address)
    return @kernal_rom[address - 0xE000] if @hiram == 1
    @ram[address]
  end

  def write_io_or_char_rom(address, value)
    if @charen == 1 && @hiram == 1 && @exrom == 0
      @io_devices.write_io(address, value)
    end
    # Ignore writes to ROM areas and char ROM
  end

  def load_rom(filename)
    # Implement ROM loading logic here
    File.binread(filename).bytes
  end

  def setup_io_devices
    {
      # Initialize and set up VIC-II, SID, CIA, etc.
      # Example: vic: VICII.new, sid: SID.new, cia1: CIA.new, cia2: CIA.new
      # Add other devices as needed
    }
  end
end
