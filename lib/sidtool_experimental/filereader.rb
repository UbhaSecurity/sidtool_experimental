# FileReader.rb
module Sidtool
  class FileReader
    attr_reader :format, :version, :init_address, :play_address, :songs, :start_song
    attr_reader :name, :author, :released
    attr_reader :data

    # Reads and parses a SID file
    def self.read(path)
      contents = File.open(path, 'rb', encoding: 'ascii-8bit') { |file| file.read }
      raise "File is too small. The file may be corrupt." unless contents.length >= 0x7C

      format = contents[0..3]
      raise "Unknown file format: #{format}. Only PSID/RSID are supported." unless ['PSID', 'RSID'].include?(format)

      version = read_word(contents[4..5])
      raise "Invalid version number: #{version}. Only versions 2, 3, and 4 are supported." unless [2, 3, 4].include?(version)

      data_offset = read_word(contents[6..7])
      load_address = read_word(contents[8..9])
      init_address = read_word(contents[10..11])
      play_address = read_word(contents[12..13])
      songs = read_word(contents[14..15])
      start_song = read_word(contents[16..17])

      name = read_null_terminated_string(contents[22..53])
      author = read_null_terminated_string(contents[54..85])
      released = read_null_terminated_string(contents[86..117])

      data = read_bytes(contents[data_offset..-1])

      new(format: format, version: version, init_address: init_address, play_address: play_address,
          songs: songs, start_song: start_song, name: name, author: author, released: released, data: data)
    end

    def initialize(format:, version:, init_address:, play_address:, songs:, start_song:, name:, author:, released:, data:)
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
