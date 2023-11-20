# Include the required modules and classes
require_relative 'sidtool/synth'
require_relative 'sidtool/voice'
require_relative 'sidtool/emulator'

class C64Emulator
  def initialize
    # Initialize the necessary components
    @memory = Memory.new
    @cpu = Mos6510::Cpu.new(@memory)
    @sid = Sidtool::Sid6581.new # Create an instance of Sid6581 from Sidtool module
    @synth = Sidtool::Synth.new # A synthesizer to work with SID chip sound synthesis
    @voice = Sidtool::Voice.new # Represents a single voice in the SID chip
    @state = EmulatorState.new # Holds the state of the emulator (running, stopped, etc.)
    @display = Display.new # Placeholder for display handling (VIC-II chip)
    @keyboard = Keyboard.new # Placeholder for keyboard handling
  end

  def load_program(program_data, start_address)
    @cpu.load_program(program_data, start_address)
  end

  def run
    @cpu.reset
    until @state.emulation_finished?
      @cpu.step # Execute a single instruction

      # Integrate SID chip memory read and write
      sid_address = @cpu.get_sid_address
      sid_data = @memory.read_io(sid_address)
      @sid.write_register(sid_address, sid_data)
      sid_audio = @sid.generate_audio
      @synth.process(sid_audio)

      @display.refresh # Refresh display if needed
      @keyboard.check_input # Check for user input
      @state.update # Update emulator state
    end
  end

  def stop
    @state.emulation_finished = true
  end
end
