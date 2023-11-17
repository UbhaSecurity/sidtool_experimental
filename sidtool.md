# Sidtool Module in Ruby

This Ruby module `Sidtool` is designed for SID chip emulation, particularly for the PAL system. 
It includes a variety of classes and constants that are essential for accurately emulating the SID chip found in the Commodore 64.

## Requirements

The module requires several Ruby files and classes to function:

- `sidtool/version`
- `sidtool/file_reader`
- `sidtool/ruby_file_writer`
- `sidtool/midi_file_writer`
- `sidtool/synth`
- `sidtool/voice`
- `sidtool/sid`
- `sidtool/state`
- `sidtool/sid_6581`
- `mos6510`

## Module Contents

### Constants

The module defines several constants specific to the PAL system:

- `FRAMES_PER_SECOND`: Sets the frame rate for the emulation (50.0 for PAL).
- `CLOCK_FREQUENCY`: Sets the clock frequency of the SID chip in the PAL system (985248.0).

It also includes constants for slide detection and handling:

- `SLIDE_THRESHOLD`
- `SLIDE_DURATION_FRAMES`

### Global State Object

A global `STATE` object is created for managing the overall state of the SID emulation.

### SidWrapper Class

The `SidWrapper` class interfaces with the SID chip and CIA timers. It includes methods for writing to the SID chip's registers and emulating a single cycle of the SID chip.

### Initialization and Emulation Methods

- `initialize_sid_emulation`: Class method to set up the SidWrapper and Mos6510 CPU.
- `emulate`: Class method to run the emulation loop.

### Initialization Call

Finally, the SID emulation setup is initialized by calling `Sidtool.initialize_sid_emulation`.

```ruby
# Require necessary components for the Sidtool module.
require 'sidtool/version'
require 'sidtool/file_reader'
# ... other requires
require 'sidtool/state'
require 'sidtool/sid_6581'
require 'mos6510'

module Sidtool
  # ... module contents
end

# Initialize the SID emulation setup
Sidtool.initialize_sid_emulation
```

## Usage

To use this module, simply include it in your Ruby environment and call the initialization method. 
This will start the SID chip emulation process.
