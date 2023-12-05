module SidtoolExperimental
  class FileReader
    attr_reader :format, :version, :init_address, :play_address, :songs, :start_song
    attr_reader :name, :author, :released
    attr_reader :data, :load_address, :speed, :flags, :start_page, :page_length, :second_sid_address, :third_sid_address

    # Reads and parses a SID file
    def self.read(path)
      puts "Reading SID file: #{path}" # Debug: Print the path of the file being read
      contents = File.open(path, 'rb', encoding: 'ascii-8bit') { |file| file.read }
      raise "File is too small. The file may be corrupt." unless contents.length >= 0x7C

      format = contents[0..3]
      puts "File Format: #{format}" # Debug: Print the file format

      version = read_word(contents[4..5])
      puts "File Version: #{version}" # Debug: Print the file version

      data_offset = read_word(contents[6..7])
      puts "Data Offset: #{data_offset}" # Debug: Print the data offset

      load_address = read_word(contents[8..9])
      puts "Load Address: #{load_address}" # Debug: Print the load address

      init_address = read_word(contents[10..11])
      puts "Init Address: #{init_address}" # Debug: Print the init address

      play_address = read_word(contents[12..13])
      puts "Play Address: #{play_address}" # Debug: Print the play address

      songs = read_word(contents[14..15])
      puts "Number of Songs: #{songs}" # Debug: Print the number of songs

      start_song = read_word(contents[16..17])
      puts "Start Song: #{start_song}" # Debug: Print the start song

      name = read_null_terminated_string(contents[22..53])
      puts "Name: #{name}" # Debug: Print the name

      author = read_null_terminated_string(contents[54..85])
      puts "Author: #{author}" # Debug: Print the author

      released = read_null_terminated_string(contents[86..117])
      puts "Released: #{released}" # Debug: Print the released information

      data = read_bytes(contents[data_offset..-1])

      new(format: format, version: version, init_address: init_address, play_address: play_address,
          songs: songs, start_song: start_song, name: name, author: author, released: released, data: data,
          load_address: load_address, speed: speed, flags: flags, start_page: start_page,
          page_length: page_length, second_sid_address: second_sid_address, third_sid_address: third_sid_address)
    end

    def initialize(format:, version:, init_address:, play_address:, songs:, start_song:, name:, author:, released:, data:,
                   load_address:, speed:, flags:, start_page:, page_length:, second_sid_address:, third_sid_address:)
      @format = format
      @version = version
      @init_address = init_address
      @play_address = play_address
      @songs = songs
      @start_song = start_song
      @name = name
      @author = author
      @released = released
      @data = data
      @load_address = load_address
      @speed = speed
      @flags = flags
      @start_page = start_page
      @page_length = page_length
      @second_sid_address = second_sid_address
      @third_sid_address = third_sid_address
    end

    # Emulates the SID file
    def emulate_sid
      emulator = C64Emulator.new
      emulator.load_program(@data, @load_address)
      emulator.setup_environment(@format, @version, @speed, @flags, @start_page, @page_length, @second_sid_address, @third_sid_address)
      emulator.run(@init_address, @play_address, @songs, @start_song)
      emulator
    end

    private

    def self.read_word(bytes)
      (bytes[0].ord << 8) + bytes[1].ord
    end

    def self.read_null_terminated_string(bytes)
      first_null = bytes.index("\0") || 32
      bytes[0..first_null - 1]
    end

    def self.read_bytes(bytes)
      bytes.chars.map(&:ord)
    end
  end
end
