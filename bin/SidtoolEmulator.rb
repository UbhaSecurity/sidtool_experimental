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
require_relative '../lib/sidtool_experimental/Mos6510'

module SidtoolExperimental
  class SidtoolEmulator
    CPU_FREQUENCY = 1_000_000 # 1 MHz
    AUDIO_SAMPLE_RATE = 44_100 # 44.1 kHz
    CYCLES_PER_FRAME = CPU_FREQUENCY / AUDIO_SAMPLE_RATE
    MAX_BUFFER_SIZE = 44100 * 10 # Example size, 10 seconds of audio at 44.1 kHz

    attr_accessor :memory, :cpu, :cia_timer_a, :cia_timer_b, :sid6581, :cycle_count, :audio_buffer, :current_frame

    def initialize
      @memory = Memory.new
      @cpu = Mos6510.new(@memory, self)
      @cia_timer_a = CIATimer.new(self)
      @cia_timer_b = CIATimer.new(self)
      @sid6581 = Sid6581.new(memory: @memory)
      @cycle_count = 0
      @audio_buffer = []
      @current_frame = 0
    end

    def load_sid_file(file_path)
      sid_file = FileReader.read(file_path)

      raise 'Memory not initialized' unless @memory.is_a?(Memory)
      raise 'Invalid start address' unless @memory.valid_address?(sid_file.load_address)

      @cpu.load_program(sid_file.data, sid_file.load_address)
      setup_sid_environment(sid_file)
    end

    def run
      until emulation_finished?
        run_cycle
      end
    end

    def stop
      @emulation_finished = true
    end

    def run_cycle
      @cpu.step
      @sid6581.update_sid_state
      @cia_timer_a.update
      @cia_timer_b.update
      process_audio
      @current_frame += 1
      handle_frame_update if frame_completed?
    end

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

      emulator = SidtoolExperimental::SidtoolEmulator.new
      emulator.load_and_run_sid_file(input_file)
    end

    private

    def self.parse_arguments
      options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: ruby your_program.rb [options] input_file.sid"

        # You can add options and their descriptions here if needed

        opts.on("-h", "--help", "Display this help message") do
          puts opts
          exit
        end
      end.parse!

      options
    end

    def setup_sid_environment(sid_file)
      @cpu.pc = sid_file.init_address
      handle_extended_sid_file(sid_file) if sid_file.version >= 2
    end

    def frame_completed?
      @cycle_count >= CYCLES_PER_FRAME
    end

    def handle_frame_update
      @cycle_count = 0
      process_audio
      manage_audio_buffer
      increment_frame
    end

    def process_audio
      frame_audio_output = @sid6581.process_audio(AUDIO_SAMPLE_RATE)
      @audio_buffer.concat(frame_audio_output)
    end

    def manage_audio_buffer
      if @audio_buffer.size > MAX_BUFFER_SIZE
        output_audio_buffer_to_file("output.wav")
        @audio_buffer.clear
      end
    end

    def output_audio_buffer_to_file(filename)
      format = WavFile::Format.new(:mono, :pcm_16, AUDIO_SAMPLE_RATE, @audio_buffer.size)
      data_chunk = WavFile::DataChunk.new(@audio_buffer.pack('s*'))
      File.open(filename, "wb") { |file| WavFile.write(file, format, [data_chunk]) }
    end

    def increment_frame
      @current_frame += 1
    end

    def handle_extended_sid_file(sid_file)
      # Handle additional features for extended SID files
    end

    def emulation_finished?
      @emulation_finished
    end

    # Other methods as needed...
  end
end
