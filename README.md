# Sidtool Experimental Project

## Overview
The Sidtool Experimental Project is an advanced emulation suite for the SID (Sound Interface Device) chip, primarily found in the Commodore 64. 
This project aims to accurately replicate the sound synthesis capabilities of the SID chip for music creation, educational purposes, and historical preservation.

## File Descriptions and Functionalities

### 1. voice.rb
- **Description**: Manages the synthesis voices of the SID chip.
- **Key Functions**:
  - `initialize`: Sets up a new voice instance.
  - `update_parameters`: Adjusts voice parameters like frequency and waveform.
  - `apply_adsr_envelope(attack, decay, sustain, release)`: Applies the ADSR envelope to the voice.

### 2. synth.rb
- **Description**: Core synthesis engine for generating audio waveforms.
- **Key Functions**:
  - `generate_waveform(wave_type, frequency)`: Generates a specific waveform.
  - `modulate_waveform(lfo_rate, lfo_depth)`: Applies LFO modulation to the waveform.

### 3. state.rb
- **Description**: Handles the state management of the SID emulation.
- **Key Functions**:
  - `save_state`: Saves the current state of the emulation.
  - `load_state(state_file)`: Loads a saved state from a file.

### 4. sidtool.rb
- **Description**: Main script for initializing and running the SID emulation.
- **Key Functions**:
  - `setup_emulation`: Configures and initializes the emulation environment.
  - `run_emulation`: Starts the emulation process.

### 5. Sid6581.rb
- **Description**: Specific emulation of the SID 6581 chip model.
- **Key Functions**:
  - `write_register(address, value)`: Writes a value to a specific register in the SID chip.
  - `read_register(address)`: Reads the value from a specific register.

### 6. sid.rb
- **Description**: General interface for the SID chip functionalities.
- **Key Functions**:
  - `play_note(note, duration)`: Plays a note for a specified duration.
  - `stop_note(note)`: Stops a currently playing note.

### 7. Mos6510.rb
- **Description**: Emulator for the MOS 6510 CPU used in Commodore 64.
- **Key Functions**:
  - `execute_instruction(instruction)`: Executes a CPU instruction.
  - `handle_interrupt`: Handles CPU interrupts.

### 8. filereader.rb
- **Description**: Reads and interprets data files for SID emulation.
- **Key Functions**:
  - `read_file(file_path)`: Reads data from a specified file.
  - `parse_data(data)`: Parses raw data into a usable format.

### 9. midi_file_writer.rb
- **Description**: Converts SID emulation data to MIDI format.
- **Key Functions**:
  - `convert_to_midi(sid_data)`: Converts SID data to MIDI.
  - `write_midi_file(midi_data, file_path)`: Writes MIDI data to a file.

### 10. LICENSE
- Contains the licensing information for the project.

### 11. README.md
- This file, providing detailed documentation for the project.

## Additional Resources
- [Commodore 64 SID Chip Overview](https://www.c64-wiki.com/wiki/SID)
- [SID 6581/8580 Datasheet](http://www.waitingforfriday.com/index.php/Commodore_SID_6581_Datasheet)
- [MOS 6510 CPU Details](https://en.wikipedia.org/wiki/MOS_Technology_6510)
