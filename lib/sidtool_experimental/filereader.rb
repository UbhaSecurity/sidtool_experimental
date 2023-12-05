module SidtoolExperimental
  class FileReader
    attr_reader :format, :version, :data_offset, :load_address, :init_address, :play_address, 
                :songs, :start_song, :speed, :flags, :start_page, :page_length, 
                :second_sid_address, :third_sid_address, :name, :author, :released, :data

    # Reads and parses a SID file
    def self.read(path)
      puts "Reading SID file: #{path}"
      
      contents = File.open(path, 'rb', encoding: 'ascii-8bit') { |file| file.read }
      
      raise "File is too small. The file may be corrupt." unless contents.length >= 0x7C

      format = contents[0..3]
      version = read_word(contents[4..5])
      data_offset = read_word(contents[6..7])
      load_address = read_word(contents[8..9])
      init_address = read_word(contents[10..11])
      play_address = read_word(contents[12..13])
      songs = read_word(contents[14..15])
      start_song = read_word(contents[16..17])
      speed = read_word(contents[114..115])
      flags = read_word(contents[116..117])
      start_page = contents[118].ord
      page_length = contents[119].ord
      second_sid_address = read_word(contents[120..121])
      third_sid_address = read_word(contents[122..123])
      name = read_null_terminated_string(contents[18..49])
      author = read_null_terminated_string(contents[50..81])
      released = read_null_terminated_string(contents[82..113])
      data = contents[data_offset..-1].bytes # Convert data to an array of byte values

      new(
        format: format, version: version, data_offset: data_offset, load_address: load_address,
        init_address: init_address, play_address: play_address, songs: songs, start_song: start_song,
        name: name, author: author, released: released, speed: speed, flags: flags, 
        start_page: start_page, page_length: page_length, second_sid_address: second_sid_address, 
        third_sid_address: third_sid_address, data: data
      )
    end

    private

    def initialize(params)
      @format = params[:format]
      @version = params[:version]
      @data_offset = params[:data_offset]
      @load_address = params[:load_address]
      @init_address = params[:init_address]
      @play_address = params[:play_address]
      @songs = params[:songs]
      @start_song = params[:start_song]
      @speed = params[:speed]
      @flags = params[:flags]
      @start_page = params[:start_page]
      @page_length = params[:page_length]
      @second_sid_address = params[:second_sid_address]
      @third_sid_address = params[:third_sid_address]
      @name = params[:name]
      @author = params[:author]
      @released = params[:released]
      @data = params[:data]
    end

    def self.read_word(bytes)
      (bytes[0].ord << 8) + bytes[1].ord
    end

    def self.read_null_terminated_string(bytes)
      first_null = bytes.index("\0") || 32
      bytes[0..first_null - 1]
    end
  end
end
