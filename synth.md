Here's the Markdown code with formatting for your `Synth` class documentation:

```markdown
# Sidtool::Synth Class

The `Synth` class is a component of the `Sidtool` module, responsible for sound synthesis and modulation. It includes an LFO (Low-Frequency Oscillator) to modulate various parameters of the synthesizer, allowing for dynamic and expressive sound shaping.

## LFO Overview

- **Low Frequency:** Operates below the human hearing threshold, typically below 20 Hz.
- **Oscillator:** Regularly varies over time, influencing other sound parameters.

### LFO Parameters

1. **Rate/Speed:** Determines the oscillation speed. A faster rate equals rapid modulation.
2. **Depth/Intensity:** Controls the extent of the LFO's effect on the modulated parameter.
3. **Waveform:** Shapes of the wave (sine, square, triangle, etc.) affect the modulation style.
4. **Phase:** Starting point in the waveform’s cycle, useful for synchronization.
5. **Destination:** The parameter being modulated (e.g., pitch, volume, filter cutoff).

## LFO Uses in Synths

- Modulating synth parameters like pitch, amplitude, filter cutoff for effects like vibrato, tremolo, wah-wah.
- Applying to audio effect parameters, creating dynamic effects.
- Serving as an alternative to manual automation in DAWs.
- Creating rhythmic elements by syncing to the track's tempo.
- Expanding sound design possibilities with evolving textures and patterns.

## Advanced Techniques

- **LFO on LFO:** Complex modulations by applying an LFO to another LFO's parameters.
- **Envelope-Controlled LFOs:** Using envelopes to dynamically control LFO settings.
- **MIDI Sync:** Ensuring rhythmic consistency by syncing LFOs to the MIDI clock.

## Usage Tips

- Use subtlety for modulation depth.
- Experiment with different waveforms for varied effects.
- Consider the mix impact of LFO-modulated tracks.
- Utilize automation for LFO parameter variation.

### handle_attack_decay_sustain_release Method

This method manages the mapping of the SID's ADSR (Attack, Decay, Sustain, Release) parameters to MIDI control messages. The ADSR envelope is a fundamental component in sound synthesis, shaping the amplitude envelope of a sound.

#### ADSR Overview

- **Attack:** Time it takes for the sound to reach its maximum level after a key is pressed.
- **Decay:** Time for the sound to decrease to the sustain level after the initial peak.
- **Sustain:** The level at which the sound remains after the decay phase, as long as the key is held down.
- **Release:** Time for the sound to fade to silence after the key is released.

The method converts ADSR values into MIDI controller messages, allowing for dynamic control over sound shaping in a MIDI environment.

**Usage Notes:**

- Each ADSR phase can be mapped to a specific MIDI controller number.
- The method scales the ADSR parameters to fit the MIDI controller value range (0-127).
- This implementation provides a basic mapping that can be adjusted according to specific needs or hardware/software specifications.

The ADSR envelope is crucial for adding expressiveness and dynamic characteristics to the synthesized sound.

```ruby
# Example usage of the handle_attack_decay_sustain_release method
def handle_attack_decay_sustain
