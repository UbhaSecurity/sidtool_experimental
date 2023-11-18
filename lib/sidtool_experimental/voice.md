# Voice Class

The `Voice` class is a part of the `Sidtool` module and represents an individual voice on the MOS Technology 6581 SID (Sound Interface Device) chip. Each SID chip has three voices, and this class provides functionality for controlling and modulating the properties of a single voice.

## Attributes

- `frequency_low` (Integer): The low byte of the voice's frequency.
- `frequency_high` (Integer): The high byte of the voice's frequency.
- `pulse_low` (Integer): The low byte of the pulse width.
- `pulse_high` (Integer): The high byte of the pulse width.
- `control_register` (Integer): The control register value for the voice.
- `attack_decay` (Integer): The attack/decay register value.
- `sustain_release` (Integer): The sustain/release register value.
- `synths` (Array): An array of synthesizers associated with this voice.

## Initialization

```ruby
module Sidtool
  class Voice
    # Initialize a new Voice instance with a reference to the SID chip and its voice number.
    #
    # @param sid6581 [Sid6581] Reference to the SID chip instance.
    # @param voice_number [Integer] The number of the voice on the SID chip.
    def initialize(sid6581, voice_number)
      # ...
    end
  end
end
```

In the constructor, a new `Voice` instance is initialized with default values for its attributes.

## Public Methods

### `finish_frame`

Updates the state of the voice at the end of each frame.

```ruby
def finish_frame
  # ...
end
```

### `stop!`

Immediately stops the current synthesizer associated with the voice.

```ruby
def stop!
  # ...
end
```

## Private Methods

### `gate`

Determines if the gate flag is set in the control register.

```ruby
def gate
  # ...
end
```

### `frequency`

Calculates the frequency from the low and high byte values.

```ruby
def frequency
  # ...
end
```

### `waveform`

Determines the waveform type based on the control register.

```ruby
def waveform
  # ...
end
```

### `attack`

Converts the attack value from SID format to a usable format.

```ruby
def attack
  # ...
end
```

### `decay`

Converts the decay value from SID format to a usable format.

```ruby
def decay
  # ...
end
```

### `release`

Converts the release value from SID format to a usable format.

```ruby
def release
  # ...
end
```

### `update_sustain_level`

Updates the sustain level based on the sustain_release register.

```ruby
def update_sustain_level
  # ...
end
```

### `handle_gate_on`

Handles logic when the gate is on.

```ruby
def handle_gate_on
  # ...
end
```

### `handle_gate_off`

Handles logic when the gate is off.

```ruby
def handle_gate_off
  # ...
end
```

### `update_synth_properties`

Updates properties of the current synthesizer associated with the voice.

```ruby
def update_synth_properties
  # ...
end
```

### `handle_midi_note_change`

Handles a change in MIDI note.

```ruby
def handle_midi_note_change(midi_note)
  # ...
end
```

### `slide_detected?`

Detects if a slide is occurring between two MIDI notes.

```ruby
def slide_detected?(prev_midi_note, new_midi_note)
  # ...
end
```

### `handle_slide`

Handles a slide between two MIDI notes.

```ruby
def handle_slide(start_midi, end_midi)
  # ...
end
```

### `midi_to_frequency`

Converts a MIDI note number to a frequency.

```ruby
def midi_to_frequency(midi_note)
  # ...
end
```

### `frequency_to_midi`

Converts a frequency to a MIDI note number.

```ruby
def frequency_to_midi(frequency)
  # ...
end
```

### `convert_attack`

Converts the SID's attack rate value to a corresponding time duration.

```ruby
def convert_attack(attack)
  # ...
end
```

### `convert_decay_or_release`

Converts the SID's decay or release value to a duration in seconds.

```ruby
def convert_decay_or_release(decay_or_release)
  # ...
end
```
