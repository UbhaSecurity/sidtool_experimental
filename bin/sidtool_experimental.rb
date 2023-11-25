# sidtool_experimental.rb
require 'optparse'
require_relative '../lib/sidtool_experimental/filereader'
require_relative '../lib/sidtool_experimental/midi_file_writer'
require_relative '../lib/sidtool_experimental/Mos6510'
require_relative '../lib/sidtool_experimental/Sid6581'
require_relative '../lib/sidtool_experimental/state'
require_relative '../lib/sidtool_experimental/synth'
require_relative '../lib/sidtool_experimental/voice'
require_relative '../lib/sidtool_experimental/version'
require_relative '../lib/sidtool_experimental/C64Emulator'
require_relative '../lib/sidtool_experimental/memory'
require_relative '../lib/sidtool_experimental/CIATimer'
require_relative '../lib/sidtool_experimental/RubyFileWriter'

module SidtoolExperimental
  FRAMES_PER_SECOND = 50.0
  CLOCK_FREQUENCY = 985248.0
  SLIDE_THRESHOLD = 60
  SLIDE_DURATION_FRAMES = 20
  DEFAULT_FRAME_COUNT = 5000

  def self.parse_arguments
    options = { frames: DEFAULT_FRAME_COUNT, format: 'ruby' }
    OptionParser.new do |opts|
      opts.banner = "Usage: sidtool_experimental [options] <inputfile.sid>"
      opts.on('-i', '--info', 'Show file information')
      opts.on('--format FORMAT', 'Output format, "ruby" or "midi"') do |format|
        options[:format] = format.downcase
        unless EXPORTERS.key?(options[:format])
          puts "Invalid format specified. Supported formats: ruby, midi."
          exit(1)
        end
      end
      opts.on('-o', '--out FILENAME', 'Output file')
      opts.on('-s', '--song NUMBER', Integer, 'Song number to process (defaults to the start song in the file)')
      opts.on('-f', '--frames NUMBER', Integer, "Number of frames to process (default #{DEFAULT_FRAME_COUNT})")
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end.parse!
    options
  end

  STATE = State.new

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
    run_emulation(options)
  end

  def self.run_emulation(options)
    c64_emulator = C64Emulator.new
    c64_emulator.load_program(File.binread(input_file), 0x0801) # Example load address

    if options[:info]
      # TODO: Display file information
    else
      emulate(c64_emulator, options[:frames])
    end
  end

  def self.emulate(emulator, frame_limit)
    frame_count = 0
    loop do
      break if frame_count >= frame_limit
      emulator.run
      frame_count += 1
    end
    # Post-emulation tasks, like saving the output
    exporter.export(output_file, STATE)
  end
end

SidtoolExperimental.run
