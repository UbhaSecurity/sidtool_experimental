# Sidtool Experimental Project

## Overview
The Sidtool Experimental Project, based on by Ole Friis Østergaard sidtool , is an intricate emulation suite for the SID (Sound Interface Device) chip used in the Commodore 64.
 This project facilitates the accurate emulation of the SID's sound synthesis capabilities for educational purposes, musical production, and technological preservation.

## Project Details
- **Author**: Ole Friis Østergaard
- (c) Ulf Bertilsson (Experimental fork)
- **Source Code**: [GitHub Repository](https://github.com/olefriis/sidtool)

## File Descriptions, Functionalities, and Constants

### General Constants
- **FRAMES_PER_SECOND**: Defines the emulation's frame rate, set to match the PAL system's 50 frames per second.
- **CLOCK_FREQUENCY**: Specifies the clock frequency of the SID chip in a PAL system, set at 985248 Hz, which is crucial for timing and sound generation.
- **SLIDE_THRESHOLD**: Used in voice handling to determine when a slide between notes is significant enough to be considered a slide rather than a direct step.
- **SLIDE_DURATION_FRAMES**: Defines how many frames a slide between notes should take, affecting the portamento effect between pitches.

### Sidtool Module (sidtool.rb)
- **Purpose**: Orchestrates the initialization and execution of the SID emulation.
- **Key Functionalities**:
  - **initialize_sid_emulation**: Prepares the emulation environment.
  - **emulate**: Engages the emulation process, calling the `emulate_cycle` method in a loop.

### Sid Class (sid.rb)
- **Purpose**: Manages the SID chip's state and operations, including register reads/writes and the emulation cycle.
- **Key Functionalities**:
  - **initialize**: Sets up the SID emulation environment with timers and voices.
  - **emulate_cycle**: Performs a single cycle of SID chip emulation, a cornerstone for sound production.

### Mos6510 Class (Mos6510.rb)
- **Purpose**: Emulates the MOS 6510 CPU, integral to the Commodore 64's operation and the SID's functioning.
- **Key Functionalities**:
  - **initialize**: Sets up the CPU emulation, including memory and SID reference.
  - **set_mem/get_mem**: Manages memory operations and SID register interactions.
  - **step**: Processes a single CPU instruction and updates the cycle count.

### MidiFileWriter Class (midi_file_writer.rb)
- **Purpose**: Transforms SID synthesizer data into a MIDI format usable in various DAWs.
- **Key Functionalities**:
  - **write_to**: Outputs MIDI data to a file, translating SID synthesis into MIDI tracks.
  - **build_track**: Converts synthesizer parameters into MIDI messages, encapsulating waveform and ADSR envelope handling.

### Voice Class (voice.rb)
- **Purpose**: Handles individual voices of the SID chip, managing waveform generation and ADSR envelope processing.
- **Key Functionalities**:
  - **initialize**: Constructs a new voice with references to the SID chip and its parameters.
  - **finish_frame**: Concludes the processing of a single frame, updating voice state accordingly.

### Synth Class (synth.rb)
- **Purpose**: Manages audio synthesis, including waveform generation and modulation.
- **Key Functionalities**:
  - **initialize**: Starts a new synth instance, setting default parameters and initializing modulation controls.
  - **frequency=**: Assigns a frequency to the synth, managing slides and frequency transitions.

### FileReader Class (filereader.rb)
- **Purpose**: Reads and interprets input files for SID emulation, parsing raw data into structured formats.
- **Key Functionalities**: 
  - Detailed methods and functionality should be described here based on the specifics of the `filereader.rb` file.

### Sid6581 Class (Sid6581.rb)
- **Purpose**: Emulates the specific functionalities of the SID 6581 chip model.
- **Key Functionalities**: 
  - Detailed methods and functionality should be described here based on the specifics of the `Sid6581.rb` file.

### State Class (state.rb)
- **Purpose**: Maintains the state of the SID emulation, including the current settings and statuses of various components.
- **Key Functionalities**: 
  - Detailed methods and functionality should be described here based on the specifics of the `state.rb` file.

## Additional Resources
- [Commodore 64 SID Chip Overview](https://www.c64-wiki.com/wiki/SID)
- [SID 6581/8580 Datasheet](http://www.waitingforfriday.com/index.php/Commodore_SID

_6581_Datasheet)
- [MOS 6510 CPU Details](https://en.wikipedia.org/wiki/MOS_Technology_6510)
