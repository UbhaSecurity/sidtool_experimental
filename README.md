# Sidtool Experimental Project

## Overview
The Sidtool Experimental Project, created by Ole Friis Østergaard, is a sophisticated emulation and interaction suite for the SID (Sound Interface Device) chip, notably used in the Commodore 64. This project aims to accurately replicate the SID's sound synthesis capabilities for educational, musical, and historical preservation purposes.

## Project Details
- **Author**: Ole Friis Østergaard
- (c) Ulf Bertilsson (EXPERIMENTAL VERSION)
- **Source Code**: [GitHub Repository](https://github.com/olefriis/sidtool)

## File Descriptions and Functionalities

### 1. Sidtool Module (sidtool.rb)
- **Purpose**: Main interface and control script for the SID emulation tool.
- **Key Functionalities**:
  - **initialize_sid_emulation**: Sets up the emulation environment with `SidWrapper` and `Mos6510::Cpu`.
  - **emulate**: Runs the main emulation loop, handling SID chip cycles.

### 2. Sid Class (sid.rb)
- **Purpose**: Manages SID chip operations, including register reads/writes and cycle emulation.
- **Key Functionalities**:
  - **write_register**: Handles writing values to SID chip registers.
  - **read_register**: Manages reading values from SID chip registers.
  - **emulate_cycle**: Emulates a single cycle of the SID chip, updating timers and generating sound.

### 3. Mos6510 Class (Mos6510.rb)
- **Purpose**: Emulates the MOS Technology 6510 microprocessor.
- **Key Functionalities**:
  - **set_mem/get_mem**: Manages memory read/write operations.
  - **step**: Executes one instruction of the CPU.
  - **run_cycles**: Runs a specified number of CPU cycles.

### 4. MidiFileWriter Class (midi_file_writer.rb)
- **Purpose**: Converts SID parameters to MIDI format for use in digital audio workstations (DAWs).
- **Key Functionalities**:
  - **write_to**: Writes MIDI data to a specified file path.
  - **build_track**: Constructs a MIDI track from synthesizer parameters.

### 5. Voice Class (voice.rb)
- **Purpose**: Manages individual voices of the SID chip.
- **Key Functionalities**:
  - **initialize**: Sets up a new voice instance.
  - **finish_frame**: Updates the state of the voice at the end of each frame.
  - **frequency_to_midi** and **midi_to_frequency**: Converts between frequency and MIDI note values.

### 6. Synth Class (synth.rb)
- **Purpose**: Handles the synthesis of audio waveforms and modulation.
- **Key Functionalities**:
  - **initialize**: Initializes a new synth instance.
  - **frequency=**: Sets the frequency and manages slides.
  - **release!**: Triggers the release phase of the synth.

### 7. FileReader Class (filereader.rb)
- **Purpose**: Reads and processes input files for the SID emulation.
- **Key Functionalities**:
  - Specific methods and functionalities were not detailed in the provided information.

### 8. Sid6581 Class (Sid6581.rb)
- **Purpose**: Emulates the SID 6581 chip model.
- **Key Functionalities**:
  - Specific methods and functionalities were not detailed in the provided information.

### 9. State Class (state.rb)
- **Purpose**: Manages the state of the SID emulation.
- **Key Functionalities**:
  - Specific methods and functionalities were not detailed in the provided information.

## Usage and Setup
(Instructions on how to set up and use the project, including requirements and basic usage examples.)

## Additional Resources
- [Commodore 64 SID Chip Overview](https://www.c64-wiki.com/wiki/SID)
- [SID 6581/8580 Datasheet](http://www.waitingforfriday.com/index.php/Commodore_SID_6581_Datasheet)
- [MOS 6510 CPU Details](https://en.wikipedia.org/wiki/MOS_Technology_6510)
