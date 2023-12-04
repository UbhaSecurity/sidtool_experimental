module SidtoolExperimental
  class Memory
    attr_accessor :ram, :basic_rom, :kernal_rom, :char_rom, :io_devices
    attr_accessor :loram, :hiram, :charen, :exrom, :game, :processor_port

    def initialize
      @ram = Array.new(65536, 0) # Initialize 64KB of RAM
      @basic_rom = load_rom('basic.rom') # Load BASIC ROM content
      @kernal_rom = load_rom('kernal.rom') # Load KERNAL ROM content
      @char_rom = load_rom('character.rom') # Load Character ROM content
      @io_devices = setup_io_devices # Initialize I/O devices (VIC-II, SID, CIAs)

      # Default memory configuration attributes
      @loram = @hiram = @charen = 1 # Defaults to 1 on reset
      @exrom = @game = 0 # Defaults to 0 (no cartridge)
      @processor_port = 0x37 # Default value for processor I/O port
    end

    # Read from memory: Determines the behavior when an address is read based on its range and configuration.
    def read(address)
      config = current_memory_config # Get the current memory configuration (e.g., which ROMs are active)

      case address
      when 0xA000..0xBFFF
        # In the address range of BASIC ROM, return either BASIC ROM or RAM depending on the configuration.
        return rom_area_basic(address, config)
      when 0xD000..0xDFFF
        # In the I/O and character ROM address range, return either I/O, character ROM, or RAM.
        return io_or_char_rom(address, config)
      when 0xE000..0xFFFF
        # In the KERNAL ROM address range, return either KERNAL ROM or RAM.
        return rom_area_kernal(address, config)
      else
        # For other addresses, return RAM, but check for Ultimax mode which may leave open address space.
        return @ram[address] unless config[:ultimax_mode] && address.between?(0x1000, 0xCFFF)
      end
      nil # This is the default return for Ultimax mode open address space.
    end

    # Write to memory: Determines the behavior when a value is written to an address.
    def write(address, value)
      config = current_memory_config # Get the current memory configuration

      case address
      when 0xD000..0xDFFF
        # If the I/O is enabled and the address is within the I/O range, write to I/O.
        write_io_or_char_rom(address, value, config) if config[:io_enabled]
      when 0xA000..0xBFFF, 0xE000..0xFFFF
        # Writes to ROM areas are ignored; they are read-only.
      else
        # For other addresses, write to RAM unless in Ultimax mode with specific address constraints.
        @ram[address] = value unless config[:ultimax_mode] && address.between?(0x1000, 0xCFFF)
      end
    end


    # Implement array-like access for reading memory
    def [](address)
      validate_address(address)
      # Add logic to return the value at the given address
      # For example:
      @ram[address]
    end

    # Implement array-like access for writing to memory
    def []=(address, value)
      validate_address(address)
      # Add logic to set the value at the given address
      # For example:
      @ram[address] = value



  # Helper method to validate memory addresses
    def validate_address(address)
      unless address.between?(0x0000, 0xFFFF)
        raise "Invalid memory address: #{address}"
      end
    end

    def current_memory_config
      {
        basic_rom_enabled: @loram == 1 && @hiram == 1 && @game == 0,
        kernal_rom_enabled: @hiram == 1,
        io_enabled: @charen == 1 && @hiram == 1 && @exrom == 0,
        ultimax_mode: @game == 1 && @exrom == 1,
        # Add other configurations as needed
      }
    end

   # Enhanced load_rom method with detailed error handling and debugging
    def load_rom(filename)
      begin
        # Construct the full file path relative to this script's location
        file_path = File.join(File.dirname(__FILE__), '..', 'bin', filename)
        puts "Attempting to load ROM from: #{file_path}"

        # Check if the file exists before attempting to read
        unless File.exist?(file_path)
          raise "ROM file not found: #{file_path}"
        end

        # Read and return the ROM data
        rom_data = File.binread(file_path).bytes
        puts "Loaded ROM successfully: #{filename}, Size: #{rom_data.size} bytes"
        rom_data
      rescue StandardError => e
        # Log any errors encountered during the file read operation
        puts "Error loading ROM: #{e.message}"
        puts e.backtrace.join("\n")
        []
      end
    end

    def rom_area_basic(address, config)
      return @basic_rom[address - 0xA000] if config[:basic_rom_enabled]
      @ram[address]
    end

    def io_or_char_rom(address, config)
      if config[:charen] == 1 && config[:hiram] == 1 && config[:exrom] == 0
        return @io_devices.read_io(address)
      elsif config[:charen] == 0
        return @char_rom[address - 0xD000]
      end
      @ram[address]
    end

    def rom_area_kernal(address, config)
      return @kernal_rom[address - 0xE000] if config[:hiram]
      @ram[address]
    end

    def write_io_or_char_rom(address, value, config)
      if config[:charen] == 1 && config[:hiram] == 1 && config[:exrom] == 0
        @io_devices.write_io(address, value)
      end
      # Ignore writes to ROM areas and char ROM
    end

    def initialize_vic_registers
      Array.new(64, 0) # VIC-II has 64 registers, initialized to 0
    end

    def initialize_sid_registers
      Array.new(29, 0) # SID has 29 registers, initialized to 0
    end

    def initialize_cia_registers
      Array.new(16, 0) # Each CIA has 16 registers, initialized to 0
    end

    def address_to_vic_ii_register_index(address)
      # Map addresses to VIC-II register indices
      case address
      when 0xD000
        return 0
      when 0xD001
        return 1
      # Continue with the mapping for other VIC-II registers
      when 0xD02E
        return 46
      when 0xD02F
        return 47
      else
        # Handle unsupported VIC-II register address
        raise "Unsupported VIC-II register address: #{address.to_s(16)}"
      end
    end

    def read_vic_ii_register(address)
      # Translate the address to a register index
      register_index = address_to_vic_ii_register_index(address)

      # Access VIC-II registers
      @io_devices[:vic][register_index]
    end

    def write_vic_ii_register(address, value)
      # Translate the address to a register index
      register_index = address_to_vic_ii_register_index(address)

      # Access VIC-II registers and write the value
      @io_devices[:vic][register_index] = value
    end

    def read_cia1_register(address)
      # Translate the address to a register index for CIA #1
      register_index = address_to_cia1_register_index(address)

      # Access CIA #1 registers
      @io_devices[:cia1][register_index]
    end

    def write_cia1_register(address, value)
      # Translate the address to a register index for CIA #1
      register_index = address_to_cia1_register_index(address)

      # Access CIA #1 registers and write the value
      @io_devices[:cia1][register_index] = value
    end

    def read_cia2_register(address)
      # Translate the address to a register index for CIA #2
      register_index = address_to_cia2_register_index(address)

      # Access CIA #2 registers
      @io_devices[:cia2][register_index]
    end

    def write_cia2_register(address, value)
      # Translate the address to a register index for CIA #2
      register_index = address_to_cia2_register_index(address)

      # Access CIA #2 registers and write the value
      @io_devices[:cia2][register_index] = value
    end

    def read_io(address)
      if @io_devices.key?(address)
        return @io_devices[address].read_register
      else
        # Handle unsupported I/O read operations here
        raise "Unsupported I/O read at address #{address.to_s(16)}"
      end
    end

    def write_io(address, value)
      if @io_devices.key?(address)
        @io_devices[address].write_register(value)
      else
        # Handle unsupported I/O write operations here
        raise "Unsupported I/O write at address #{address.to_s(16)}"
      end
    end

    def rom_is_mapped?(address)
      config = current_memory_config
      return true if config[:basic_rom_enabled] && address.between?(0xA000, 0xBFFF)
      return true if config[:io_enabled] && address.between?(0xD000, 0xDFFF)
      return true if config[:kernal_rom_enabled] && address.between?(0xE000, 0xFFFF)
      false
    end

    # Setup I/O devices: Initializes the I/O device registers.
    def setup_io_devices
      {
        vic: initialize_vic_registers,
        sid: initialize_sid_registers,
        cia1: initialize_cia_registers,
        cia2: initialize_cia_registers,
        # Other devices as needed.
      }
    end
  end
end
end
