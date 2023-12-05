require 'optparse'
require_relative 'lib/sidtool_experimental/filereader'
require_relative 'lib/sidtool_experimental/midi_file_writer'
require_relative 'lib/sidtool_experimental/Sid6581'
require_relative 'lib/sidtool_experimental/synth'
require_relative 'lib/sidtool_experimental/voice'
require_relative 'lib/sidtool_experimental/version'
require_relative 'lib/sidtool_experimental/C64Emulator'
require_relative 'lib/sidtool_experimental/memory'
require_relative 'lib/sidtool_experimental/CIATimer'
require_relative 'lib/sidtool_experimental/RubyFileWriter'
require_relative 'lib/sidtool_experimental/state'
require_relative 'lib/sidtool_experimental/Mos6510'

module SidtoolExperimental
  FRAMES_PER_SECOND = 50.0
  CLOCK_FREQUENCY = 985248.0
  SLIDE_THRESHOLD = 60
  SLIDE_DURATION_FRAMES = 20
  DEFAULT_FRAME_COUNT = 5000

  EXPORTERS = {
    'ruby' => RubyFileWriter,
    'midi' => MidiFileWriter
  }

  def self.run
    options = parse_arguments

    if ARGV.empty?
      puts "Please provide the path to the input SID file."
      exit(1)
    end

    input_file = ARGV[0]
    exporter = EXPORTERS[options[:format]]
    
    unless exporter
      puts "Invalid format specified. Supported formats: ruby, midi."
      exit(1)
    end

    cpu_instance.state = state_instance

    puts "Creating C64Emulator instance..."
    c64_emulator = C64Emulator.new  # This line should instantiate Memory and CPU correctly
    puts "C64Emulator instance created."

    c64_emulator.load_program(File.binread(input_file), 0x0801) # Example load address

    if options[:info]
      display_file_info(input_file)
    else
      emulate(c64_emulator, options[:frames], exporter, options[:out], options[:song])
    end
  end

  def self.parse_arguments
    options = { frames: DEFAULT_FRAME_COUNT, format: 'ruby', info: false, out: nil, song: nil }
    OptionParser.new do |opts|
      opts.banner = "Usage: sidtool_experimental [options] <inputfile.sid>"
      opts.on('-i', '--info', 'Show file information') do
        options[:info] = true
      end
      opts.on('--format FORMAT', 'Output format, "ruby" or "midi"') do |format|
        options[:format] = format.downcase
        unless EXPORTERS.key?(options[:format])
          puts "Invalid format specified. Supported formats: ruby, midi."
          exit(1)
        end
      end
      opts.on('-o', '--out FILENAME', 'Output file') do |out|
        options[:out] = out
      end
      opts.on('-s', '--song NUMBER', Integer, 'Song number to process (defaults to the start song in the file)') do |song|
        options[:song] = song
      end
      opts.on('-f', '--frames NUMBER', Integer, "Number of frames to process (default #{DEFAULT_FRAME_COUNT})") do |frames|
        options[:frames] = frames
      end
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end.parse!
    options
  end

  def self.emulate(emulator, frame_limit, output_file, exporter, song_number)
    frame_count = 0
    loop do
      break if frame_count >= frame_limit
      emulator.run_cycle
      frame_count += 1
    end
    exporter.export(output_file, emulator.state)
  end

  def self.display_file_info(file_path)
    begin
      sid_file = FileReader.read(file_path)
      puts "File Information:"
      puts "Format: #{sid_file.format}"
      puts "Version: #{sid_file.version}"
      puts "Load Address: 0x#{sid_file.load_address.to_s(16)}"
      puts "Init Address: 0x#{sid_file.init_address.to_s(16)}"
      puts "Play Address: 0x#{sid_file.play_address.to_s(16)}"
      puts "Number of Songs: #{sid_file.songs}"
      puts "Start Song: #{sid_file.start_song}"
      puts "Name: #{sid_file.name}"
      puts "Author: #{sid_file.author}"
      puts "Released: #{sid_file.released}"
      puts "Data Size: #{sid_file.data.size} bytes"
    rescue StandardError => e
      puts "Error reading SID file: #{e.message}"
    end
  end
end

SidtoolExperimental.run
