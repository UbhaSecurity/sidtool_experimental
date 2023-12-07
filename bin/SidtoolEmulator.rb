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
      @cia_timer_a = CIATimer.new(self)
      @cia_timer_b = CIATimer.new(self)
      @cpu = Mos6510::Cpu.new(@memory, self) # Create an instance of Mos6510::Cpu
      @sid6581 = Sid6581.new(memory: @memory)
      @cycle_count = 0
      @audio_buffer = []
      @current_frame = 0
      puts "Init"
    end

    def load_and_run_sid_file(file_path)
      load_sid_file(file_path)
      run_emulation
    end

    def run
      options = parse_command_line_arguments
      if options[:file]
        load_and_run_sid_file(options[:file])
      else
        puts "Please specify a SID file to load and run using the -f or --file option."
      end
    end

puts "Should not happend"

    private

    def parse_command_line_arguments
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options]"

        opts.on("-f", "--file FILE", "Path to the SID file") do |file|
          options[:file] = file
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end.parse!

      options
    end

    def update_timers
      # Update both CIA timers
      @cia_timer_a.update
      @cia_timer_b.update
    end

    def handle_interrupts
      # Check for IRQ and NMI interrupts
      if @cpu.irq_pending? && !@interrupt_flag
        handle_irq
      end
      handle_nmi if @cpu.nmi_pending?
    end

    def update_sid
      # Update the SID chip's state
      @sid6581.update_sid_state
    end

    def handle_irq
      # Logic to handle IRQ interrupts
      @cpu.save_state
      @cpu.jump_to_address(@irq_vector)
      @cpu.restore_state
    end

    def handle_nmi
      # Logic to handle NMI interrupts
      @cpu.save_state
      @cpu.jump_to_address(@nmi_vector)
      @cpu.restore_state
    end

    def load_sid_file(file_path)
      puts "load"
      sid_file = FileReader.read(file_path)
      raise 'Memory not initialized' unless @memory.is_a?(Memory)
      raise 'Invalid start address' unless @memory.valid_address?(sid_file.load_address)
      @cpu.load_program(sid_file.data, sid_file.load_address)
      setup_sid_environment(sid_file)
    end

    def run_emulation
       puts "Start emulation"
      until @emulation_finished
        run_cycle
      end
    end

    def run_cycle
      puts "Running CPU cycle"
      @cpu.step
      # Update SID state and process audio
      update_state
      @current_frame += 1
      handle_frame_update if frame_completed?
    end

    def update_state
      update_timers
      handle_interrupts
      update_sid
    end

    def handle_frame_update
      if frame_completed?
        puts "Handling frame update"
        @cycle_count = 0
        frame_audio_output = @sid6581.process_audio(AUDIO_SAMPLE_RATE)
        @audio_buffer.concat(frame_audio_output)
        manage_audio_buffer
        @current_frame += 1
      end
    end

    def frame_completed?
      @cycle_count >= CYCLES_PER_FRAME
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

    def setup_sid_environment(sid_file)
      @cpu.pc = sid_file.init_address
      handle_extended_sid_file(sid_file) if sid_file.version >= 2
    end

    def handle_extended_sid_file(sid_file)
      # Implement logic for extended SID file features
    end
  end
end

# Usage Example
emulator = SidtoolExperimental::SidtoolEmulator.new
emulator.run
