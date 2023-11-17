# Sidtool Experimental Project

## Overview
The Sidtool Experimental Project, created by Ole Friis Østergaard, is an advanced emulation suite for the SID (Sound Interface Device) chip, primarily known from the Commodore 64. This project aims to reproduce the SID's unique sound synthesis capabilities and provide an in-depth exploration of its architecture.

## Project Details
- **Author**: Ole Friis Østergaard **
- ** Experimental version Ulf Bertilsson
- **Source Code**: [GitHub Repository](https://github.com/olefriis/sidtool)

## File Descriptions, Functionalities, and Technical Details

### 1. voice.rb
- **Class**: `Voice`
- **Subcomponents**:
  - `WaveformGenerator`: Generates various audio waveforms (e.g., square, sawtooth).
  - `ADSRController`: Manages the ADSR envelope shaping.
- **Description**: Handles the synthesis and modulation of individual voices in the SID emulation.
- **Functions**:
  - `initialize(sid: SID, voice_number: Integer)`: Sets up a new voice with SID reference.
  - `configure_waveform(waveform: Symbol, frequency: Float, pulse_width: Integer)`: Configures voice waveform.
  - `apply_adsr(attack: Integer, decay: Integer, sustain: Integer, release: Integer)`: Sets ADSR envelope with precise timing control based on SID's clock.
- **Technical Details**: Voice frequency range is from 0 to 4kHz, with pulse width modulation providing timbral variation.

### 2. synth.rb
- **Class**: `Synth`
- **Subcomponents**:
  - `LFO`: Generates low-frequency oscillations for waveform modulation.
  - `Filter`: Applies various filters (low-pass, high-pass, band-pass) to the audio signal.
- **Description**: Core audio synthesis engine, generating complex waveforms and applying modulation.
- **Functions**:
  - `generate_waveform(wave_type: Symbol, frequency: Float)`: Produces specified audio waveforms.
  - `modulate_waveform(lfo_rate: Float, lfo_depth: Integer, filter_type: Symbol)`: Applies LFO and filters to the waveform for dynamic sound shaping.
- **Technical Details**: LFO rates are typically below 20Hz, providing subtle to dramatic modulation effects.

### 3. state.rb
- **Class**: `State`
- **Subcomponents**:
  - `StateSaver`: Handles serialization of the current emulator state.
  - `StateLoader`: Manages deserialization and loading of emulator states.
- **Description**: Responsible for maintaining and restoring the state of the SID emulation.
- **Functions**:
  - `save_state(file_path: String)`: Serializes the current state into a file.
  - `load_state(file_path: String)`: Loads and applies a previously saved state.

### 4. sidtool.rb
- **Module**: `Sidtool`
- **Subcomponents**:
  - `EmulationInitializer`: Sets up the initial state and configuration for the SID emulation.
  - `EmulationRunner`: Manages the execution loop of the emulator.
- **Description**: Orchestrates the overall SID emulation process, linking various components.
- **Functions**:
  - `initialize_emulation(config: Hash)`: Configures the SID emulation environment.
  - `start_emulation()`: Executes the emulation, processing audio in real-time.

### 5. Sid6581.rb
- **Class**: `Sid6581`
- **Subcomponents**:
  - `RegisterManager`: Manages the read/write operations to the SID chip registers.
- **Description**: Emulates the SID 6581 chip, handling specific features and limitations.
- **Functions**:
  - `write_register(address: Integer, value: Integer)`: Writes data to a specified register.
  - `read_register(address: Integer)`: Reads data from a specified register.
  - `simulate_filter(cutoff: Integer, resonance: Integer)`: Simulates the SID's iconic filter characteristics.
- **Technical Details**: Emulates the distinct sound and quirks of the SID 6581 model, including its filter behavior.

### 6. sid.rb
- **Class**: `SID`
- **Subcomponents**:
  - `VoiceManager`: Coordinates the operation of multiple voices.
  - `ControlRegister`: Handles the control register operations for voice and filter settings.
- **Description**: Provides a high-level interface for interacting

 with the SID chip functionalities.
- **Functions**:
  - `play_note(note: Integer, duration: Integer, voice_id: Integer)`: Plays a note on a specified voice.
  - `adjust_volume(volume: Integer)`: Sets the master volume of the SID chip.
  - `configure_filter(filter_config: Hash)`: Adjusts the filter settings for sound shaping.

### 7. Mos6510.rb
- **Class**: `Mos6510`
- **Subcomponents**:
  - `InstructionSet`: Contains the CPU's instruction set and execution logic.
  - `InterruptHandler`: Manages interrupt signals and their processing.
- **Description**: Simulates the functionality of the MOS 6510 CPU, integral to the Commodore 64.
- **Functions**:
  - `execute_instruction(instruction: String)`: Processes a single CPU instruction.
  - `simulate_cycle()`: Simulates a single cycle of CPU operation.
  - `handle_interrupt(type: Symbol)`: Processes different types of interrupts.
- **Technical Details**: Accurately replicates the timing and behavior of the 6510 CPU, essential for SID timing accuracy.

### 8. filereader.rb
- **Class**: `FileReader`
- **Subcomponents**:
  - `DataParser`: Converts raw file data into structured emulator inputs.
  - `FileLoader`: Manages the loading of files into the emulator.
- **Description**: Reads, parses, and preprocesses data files for use in the SID emulator.
- **Functions**:
  - `read_file(file_path: String)`: Reads data from a specified file path.
  - `parse_sid_data(data: String)`: Parses SID file data for emulation.

### 9. midi_file_writer.rb
- **Class**: `MidiFileWriter`
- **Subcomponents**:
  - `MidiConverter`: Translates SID data into MIDI format.
  - `FileWriter`: Handles the writing of MIDI data to files.
- **Description**: Converts the output of the SID emulator into MIDI format for use in digital audio workstations.
- **Functions**:
  - `convert_to_midi(sid_data: Array)`: Translates SID chip data into MIDI commands.
  - `export_midi(midi_data: Array, file_path: String)`: Writes the MIDI data to a specified file path.

### 10. LICENSE
- Contains the licensing information for the project.

### 11. README.md
- This file, offering extensive documentation for the project.

## Copyright and Attribution
- (c) Ole Friis Østergaard
- (c) Ulf Bertilsson (experimental fork)
- [GitHub Repository](https://github.com/olefriis/sidtool)

## Additional Resources and Technical References
- [Commodore 64 SID Chip Overview](https://www.c64-wiki.com/wiki/SID)
- [SID 6581/8580 Datasheet](http://www.waitingforfriday.com/index.php/Commodore_SID_6581_Datasheet)
- [MOS 6510 CPU Technical Details](https://en.wikipedia.org/wiki/MOS_Technology_6510)
- [Understanding SID Chip Timings and Frequencies](https://www.sidmusic.org/sid-timing-details)

---
