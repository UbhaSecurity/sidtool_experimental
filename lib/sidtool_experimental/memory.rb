module SidtoolExperimental
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
    io_registers = {}

    # Initialize VIC-II registers
    io_registers[:vic_registers] = Array.new(64, 0)

    # Initialize SID registers
    io_registers[:sid_registers] = Array.new(29, 0)

    # Initialize CIA registers (e.g., CIA1 and CIA2)
    io_registers[:cia1_registers] = Array.new(16, 0)
    io_registers[:cia2_registers] = Array.new(16, 0)

    # You may have more I/O registers for other components

    return io_registers
  end

  # Check if the ROM is mapped at the address
  def rom_is_mapped(address)
    # Example simplified logic:
    # If the PLA's AEC (Address Enable for CPU) signal is active,
    # then the ROM is not mapped, otherwise, it is mapped.

    # Assuming you have an instance variable @pla_state that represents
    # the current state of the PLA, and AEC is one of its signals.
    # Adjust this based on your actual emulation logic.

    !@pla_state[:aec]
  end

  # Check if address is in I/O area
  def io_area?(address)
    (0xD000..0xDFFF).include?(address)
  end

   # Read from I/O registers
  def read_io(address)
    case address
    when 0xD400
      @sid6581.read_register(Sid6581::FRELO1)
    when 0xD401
      @sid6581.read_register(Sid6581::FREHI1)
    when 0xD402
      @sid6581.read_register(Sid6581::PWLO1)
    when 0xD403
      @sid6581.read_register(Sid6581::PWHI1)
    when 0xD404
      @sid6581.read_register(Sid6581::VCREG1)
    when 0xD405
      @sid6581.read_register(Sid6581::ATDCY1)
    when 0xD406
      @sid6581.read_register(Sid6581::SUREL1)
    when 0xD407
      @sid6581.read_register(Sid6581::FRELO2)
    when 0xD408
      @sid6581.read_register(Sid6581::FREHI2)
    when 0xD409
      @sid6581.read_register(Sid6581::PWLO2)
    when 0xD40A
      @sid6581.read_register(Sid6581::PWHI2)
    when 0xD40B
      @sid6581.read_register(Sid6581::VCREG2)
    when 0xD40C
      @sid6581.read_register(Sid6581::ATDCY2)
    when 0xD40D
      @sid6581.read_register(Sid6581::SUREL2)
    when 0xD40E
      @sid6581.read_register(Sid6581::FRELO3)
    when 0xD40F
      @sid6581.read_register(Sid6581::FREHI3)
    when 0xD410
      @sid6581.read_register(Sid6581::PWLO3)
    when 0xD411
      @sid6581.read_register(Sid6581::PWHI3)
    when 0xD412
      @sid6581.read_register(Sid6581::VCREG3)
    when 0xD413
      @sid6581.read_register(Sid6581::ATDCY3)
    when 0xD414
      @sid6581.read_register(Sid6581::SUREL3)
    when 0xD415
      @sid6581.read_register(Sid6581::CUTLO)
    when 0xD416
      @sid6581.read_register(Sid6581::CUTHI)
    when 0xD417
      @sid6581.read_register(Sid6581::RESON)
    when 0xD418
      @sid6581.read_register(Sid6581::SIGVOL)
    when 0xD419
      @sid6581.read_register(Sid6581::POTX)
    when 0xD41A
      @sid6581.read_register(Sid6581::POTY)
    when 0xD41B
      @sid6581.read_register(Sid6581::RANDOM)
    when 0xD41C
      @sid6581.read_register(Sid6581::ENV3)
    else
      # Handle other I/O reads here
      raise "Unsupported I/O read at address #{address.to_s(16)}"
    end
  end

  # Write to I/O registers
  def write_io(address, value)
    case address
    when 0xD400
      @sid6581.write_register(Sid6581::FRELO1, value)
    when 0xD401
      @sid6581.write_register(Sid6581::FREHI1, value)
    when 0xD402
      @sid6581.write_register(Sid6581::PWLO1, value)
    when 0xD403
      @sid6581.write_register(Sid6581::PWHI1, value)
    when 0xD404
      @sid6581.write_register(Sid6581::VCREG1, value)
    when 0xD405
      @sid6581.write_register(Sid6581::ATDCY1, value)
    when 0xD406
      @sid6581.write_register(Sid6581::SUREL1, value)
    when 0xD407
      @sid6581.write_register(Sid6581::FRELO2, value)
    when 0xD408
      @sid6581.write_register(Sid6581::FREHI2, value)
    when 0xD409
      @sid6581.write_register(Sid6581::PWLO2, value)
    when 0xD40A
      @sid6581.write_register(Sid6581::PWHI2, value)
    when 0xD40B
      @sid6581.write_register(Sid6581::VCREG2, value)
    when 0xD40C
      @sid6581.write_register(Sid6581::ATDCY2, value)
    when 0xD40D
      @sid6581.write_register(Sid6581::SUREL2, value)
    when 0xD40E
      @sid6581.write_register(Sid6581::FRELO3, value)
    when 0xD40F
      @sid6581.write_register(Sid6581::FREHI3, value)
    when 0xD410
      @sid6581.write_register(Sid6581::PWLO3, value)
    when 0xD411
      @sid6581.write_register(Sid6581::PWHI3, value)
    when 0xD412
      @sid6581.write_register(Sid6581::VCREG3, value)
    when 0xD413
      @sid6581.write_register(Sid6581::ATDCY3, value)
    when 0xD414
      @sid6581.write_register(Sid6581::SUREL3, value)
    when 0xD415
      @sid6581.write_register(Sid6581::CUTLO, value)
    when 0xD416
      @sid6581.write_register(Sid6581::CUTHI, value)
    when 0xD417
      @sid6581.write_register(Sid6581::RESON, value)
    when 0xD418
      @sid6581.write_register(Sid6581::SIGVOL, value)
    when 0xD419
      @sid6581.write_register(Sid6581::POTX, value)
    when 0xD41A
      @sid6581.write_register(Sid6581::POTY, value)
    when 0xD41B
      @sid6581.write_register(Sid6581::RANDOM, value)
    when 0xD41C
      @sid6581.write_register(Sid6581::ENV3, value)
    else
      # Handle other I/O writes here
      raise "Unsupported I/O write at address #{address.to_s(16)}"
    end
  end
end
