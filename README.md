# Sidtool Experimental Project

## Overview
The Sidtool Experimental Project is a sophisticated emulation suite for the SID (Sound Interface Device) chip of the Commodore 64, designed for sound synthesis and exploration of chip functionalities.

## File Descriptions, Functionalities, and Technical Details

### 1. voice.rb
- **Class**: `Voice`
- **Private Classes/Modules**: `WaveformGenerator`, `ADSRController`
- **Description**: Manages individual voices with waveform generation and ADSR envelope.
- **Key Functions**:
  - `initialize(sid: SID, voice_number: Integer)`: Sets up a new voice with reference to the SID instance and voice number.
  - `set_waveform(waveform: Symbol)`: Configures the waveform (square, triangle, etc.).
  - `set_frequency(frequency: Float)`: Adjusts the frequency, range typically 0-4kHz.
  - `set_pulse_width(pulse_width: Integer)`: Sets pulse width, valid range 0-4095.
  - `apply_adsr(attack: Integer, decay: Integer, sustain: Integer, release: Integer)`: Sets ADSR parameters, timing based on SID chip clock.

### 2. synth.rb
- **Class**: `Synth`
- **Private Classes/Modules**: `LFO`, `Filter`
- **Description**: Central synthesis module for audio generation.
- **Key Functions**:
  - `initialize()`: Sets up the synthesis engine.
  - `generate_waveform(wave_type: Symbol, frequency: Float)`: Generates audio waveforms.
  - `apply_lfo(lfo_rate: Float, lfo_depth: Integer)`: Modulates waveform with LFO.

### 3. state.rb
- **Class**: `State`
- **Private Classes/Modules**: `StateSaver`, `StateLoader`
- **Description**: Manages the current state and settings of the SID emulation.
- **Key Functions**:
  - `initialize()`: Initializes the state manager.
  - `save_state()`: Serializes and saves the current state.
  - `load_state(file_path: String)`: Deserializes and loads a saved state.

### 4. sidtool.rb
- **Module**: `Sidtool`
- **Private Classes/Modules**: `EmulationInitializer`, `EmulationRunner`
- **Description**: Orchestrates the initialization and execution of the SID emulation.
- **Key Functions**:
  - `initialize_emulation()`: Configures and starts the emulation setup.
  - `start_emulation()`: Executes the main emulation loop.

### 5. Sid6581.rb
- **Class**: `Sid6581`
- **Private Classes/Modules**: `RegisterManager`
- **Description**: Emulates the SID 6581 chip, handling sound generation and chip-specific features.
- **Key Functions**:
  - `write_register(address: Integer, value: Integer)`: Writes to chip registers.
  - `read_register(address: Integer)`: Reads values from chip registers.
  - `reset()`: Resets the chip to default state.

### 6. sid.rb
- **Class**: `SID`
- **Private Classes/Modules**: `VoiceManager`, `ControlRegister`
- **Description**: Interface layer for SID chip operations.
- **Key Functions**:
  - `play(note: Integer, duration: Integer)`: Plays a musical note.
  - `stop(note: Integer)`: Stops a currently playing note.
  - `set_volume(volume: Integer)`: Adjusts the overall volume.

### 7. Mos6510.rb
- **Class**: `Mos6510`
- **Private Classes/Modules**: `InstructionSet`, `InterruptHandler`
- **Description**: Emulates the MOS Technology 6510 microprocessor.
- **Key Functions**:
  - `execute(instruction: String)`: Processes an assembly instruction.
  - `interrupt()`: Manages CPU interrupts.
  - `reset()`: Resets the CPU state.

### 8. filereader.rb
- **Class**: `FileReader`
- **Private Classes/Modules**: `DataParser`, `FileLoader`
- **Description**: Reads and interprets data files for the emulator.
- **Key Functions**:
  - `read(file_path: String)`: Reads data from specified file.
  - `parse(content: String)`: Converts raw data into structured format.

### 9. midi_file_writer.rb
- **Class**: `MidiFileWriter`
- **

Private Classes/Modules**: `MidiConverter`, `FileWriter`
- **Description**: Converts SID emulation output to MIDI format.
- **Key Functions**:
  - `convert(sid_data: Array)`: Translates SID data to MIDI format.
  - `save(midi_data: Array, file_path: String)`: Writes MIDI data to a file.

### 10. LICENSE
- Contains the licensing information for the project.

### 11. README.md
- This file, providing detailed documentation for the project.

## Technical Timing and Details
- SID Clock Frequency: 0.985 MHz for PAL, 1.023 MHz for NTSC systems.
- ADSR Timing: Based on clock cycles of the SID chip.
- CPU Emulation: MOS 6510 emulation in line with C64 specifications.

## Additional Resources
- [Commodore 64 SID Chip Overview](https://www.c64-wiki.com/wiki/SID)
- [SID 6581/8580 Datasheet](http://www.waitingforfriday.com/index.php/Commodore_SID_6581_Datasheet)
- [MOS 6510 CPU Details](https://en.wikipedia.org/wiki/MOS_Technology_6510)

---
