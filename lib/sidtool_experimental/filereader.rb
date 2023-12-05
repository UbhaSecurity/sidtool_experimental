module SidtoolExperimental
  class FileReader
    # Technical Parameters:
    #
    # format          - The format of the SID file (e.g., 'PSID').
    # version         - The version of the SID file.
    # data_offset     - The offset in the file where the SID data starts.
    # load_address    - The memory address where the SID data should be loaded.
    # init_address    - The memory address where the initialization routine starts.
    # play_address    - The memory address where the SID music playback routine starts.
    # songs           - The number of songs in the SID file.
    # start_song      - The index of the starting song.
    # speed           - The speed of the SID music (unused in this code).
    # flags           - Flags specifying SID settings (e.g., SID model, clock standard).
    # start_page      - The starting page of the SID data in memory.
    # page_length     - The length of each page of SID data.
    # second_sid_address - The memory address of the second SID chip (unused in this code).
    # third_sid_address  - The memory address of the third SID chip (unused in this code).
    # name            - The name of the SID file.
    # author          - The author of the SID file.
    # released        - The release information of the SID file.
    # data            - The actual SID music data.
    
    # Reads and parses a SID file
    def self.read(path)
      # Log the path of the SID file being read
      puts "Reading SID file: #{path}"
      
      # Read the entire contents of the file into memory
      contents = File.open(path, 'rb', encoding: 'ascii-8bit') { |file| file.read }
      
      # Ensure the file is large enough to contain header information
      raise "File is too small. The file may be corrupt." unless contents.length >= 0x7C

      # Parse header information from the file
      format = contents[0..3]
      version = read_word(contents[4..5])
      data_offset = read_word(contents[6..7])
      load_address = read_word(contents[8..9])
      init_address = read_word(contents[10..11])
      play_address = read_word(contents[12..13])
      songs = read_word(contents[14..15])
      start_song = read_word(contents[16..17])
      name = read_null_terminated_string(contents[18..49])
      author = read_null_terminated_string(contents[50..81])
      released = read_null_terminated_string(contents[82..113])
      speed = read_word(contents[114..115])
      flags = read_word(contents[116..117])
      start_page = contents[118].ord
      page_length = contents[119].ord
      second_sid_address = read_word(contents[120..121])
      third_sid_address = read_word(contents[122..123])
      data = read_bytes(contents[data_offset..-1])

      # Create a new FileReader instance with the parsed data
      new(
        format: format, version: version, data_offset: data_offset, load_address: load_address,
        init_address: init_address, play_address: play_address, songs: songs, start_song: start_song,
        name: name, author: author, released: released, speed: speed, flags: flags, start_page: start_page,
        page_length: page_length, second_sid_address: second_sid_address, third_sid_address: third_sid_address,
        data: data
      )
    end

    # Determine the SID model based on flags
    def sid_model
      case (flags >> 4) & 3
      when 0
        "Unknown"
      when 1
        "MOS6581"
      when 2
        "MOS8580"
      when 3
        "MOS6581 and MOS8580"
      end
    end

    # Determine the clock standard based on flags
    def clock_standard
      case (flags >> 2) & 3
      when 0
        "Unknown"
      when 1
        "PAL"
      when 2
        "NTSC"
      when 3
        "PAL and NTSC"
      end
    end

    # Emulate the SID music using a C64 emulator
    def emulate_sid
      emulator = C64Emulator.new
      emulator.load_program(@data, @load_address)
      emulator.setup_sid_environment(self)
      emulator.run
      emulator
    end

    private

    # Helper method to read a 16-bit word from two bytes
    def self.read_word(bytes)
      (bytes[0].ord << 8) + bytes[1].ord
    end

    # Helper method to read a null-terminated string from bytes
    def self.read_null_terminated_string(bytes)
      first_null = bytes.index("\0") || 32
      bytes[0..first_null - 1]
    end

    # Helper method to read bytes as an array of ord values
    def self.read_bytes(bytes)
      bytes.chars.map(&:ord)
    end
  end
end

