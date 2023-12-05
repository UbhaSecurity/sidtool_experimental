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


  memory = Memory.new # Create an instance of Memory
  sid6581 = Sid6581.new(memory: memory) # Initialize SID6581 with memory

  # Create State instance with the necessary components
  # Note: At this point, CPU and CIATimers are not yet created, so they can't be passed to State.
  # They will be created as part of C64Emulator initialization.
  state = State.new(nil, nil, nil, sid6581) 

  # Create C64Emulator instance with sid6581
  c64_emulator = C64Emulator.new(sid6581)

  # Now that C64Emulator and its components (CPU, CIATimers) are created, update the State instance
  state.cpu = c64_emulator.cpu
  state.cia_timers = [c64_emulator.ciaTimerA, c64_emulator.ciaTimerB]
  state.emulator = c64_emulator

  # Assign State to SID6581
  sid6581.state = state

  puts "C64Emulator instance created."

    c64_emulator.load_sid_file(input_file) # Load the SID file

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

  def self.emulate(emulator, frame_limit, exporter, output_file, song_number)
    frame_count = 0
    loop do
      break if frame_count >= frame_limit
      emulator.run_cycle
      frame_count += 1
    end
    exporter.export(output_file, emulator.state)
  end

  def self.display_file_info(file_path)
    # Implementation for displaying file information
    # ...
  end

  # Additional methods and classes as needed
end

SidtoolExperimental.run
