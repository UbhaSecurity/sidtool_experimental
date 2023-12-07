require 'optparse'
require_relative '../lib/sidtool_experimental/filereader'
require_relative '../lib/sidtool_experimental/midi_file_writer'
require_relative '../lib/sidtool_experimental/Sid6581'
require_relative '../lib/sidtool_experimental/synth'
require_relative '../lib/sidtool_experimental/voice'
require_relative '../lib/sidtool_experimental/version'
require_relative '../lib/sidtool_experimental/C64Emulator'
require_relative '../lib/sidtool_experimental/memory'
require_relative '../lib/sidtool_experimental/CIATimer'
require_relative '../lib/sidtool_experimental/RubyFileWriter'
require_relative '../lib/sidtool_experimental/state'
require_relative '../lib/sidtool_experimental/Mos6510'

module SidtoolExperimental
  FRAMES_PER_SECOND = 50.0
  CLOCK_FREQUENCY = 985248.0
  SLIDE_THRESHOLD = 60
  SLIDE_DURATION_FRAMES = 20
  DEFAULT_FRAME_COUNT = 5000
  DEFAULT_LOAD_ADDRESS = 0x1000  # Default load address

  EXPORTERS = {
    'ruby' => RubyFileWriter,
    'midi' => MidiFileWriter
  }

  def self.run
    options = parse_arguments

    if ARGV.empty?
      puts "Error: Please provide the path to the input SID file."
      exit(1)
    end

    input_file = ARGV[0]

    unless File.exist?(input_file)
      puts "Error: The specified SID file does not exist: #{input_file}"
      exit(1)
    end

    begin
# Initialize Memory and Sid6581 instances
@memory = Memory.new
@sid6581 = Sid6581.new(memory: @memory)

# First, initialize the C64Emulator instance
@c64_emulator = C64Emulator.new(@memory, @sid6581)

# Now that @c64_emulator is initialized, create the State instance
@state = State.new(@c64_emulator.cpu, @c64_emulator, [@c64_emulator.ciaTimerA, @c64_emulator.ciaTimerB], @sid6581)

# Set the state for both @c64_emulator and @sid6581
@c64_emulator.state = @state
@sid6581.state = @state
@sid6581.create_voices

      puts "C64Emulator instance created."

     @c64_emulator.load_sid_file(input_file)  # Pass only the file path

    rescue StandardError => e
      puts "Error: An error occurred while loading the SID file: #{e.message}"
      exit(1)
    end

    handle_export_and_emulation(@c64_emulator, options)
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

  def self.handle_export_and_emulation(emulator, options)
    if options[:info]
      display_file_info(emulator, options)
    else
      exporter = EXPORTERS[options[:format]]
      emulate(emulator, options[:frames], exporter, options[:out], options[:song])
    end
  end

  def self.display_file_info(emulator, options)
    puts "File Information:"
    puts "Format: #{options[:format]}"
    puts "Song Number: #{options[:song]}"
    puts "Frame Count: #{options[:frames]}"
    puts "Output File: #{options[:out]}"
  end

  def self.emulate(emulator, frame_limit, exporter, output_file, song_number)
    frame_count = 0
    loop do
      break if frame_count >= frame_limit
      emulator.run_cycle
      frame_count += 1
    end
    exporter.export(output_file, emulator.state)
  end

  # Additional methods and classes as needed
end

SidtoolExperimental.run
