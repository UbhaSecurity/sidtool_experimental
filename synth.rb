# Sidtool::Synth Class
# 
# The Synth class includes an LFO (Low-Frequency Oscillator) which is a crucial element in 
# sound synthesis and modulation. The LFO in this class is designed to modulate various 
# parameters of the synthesizer, adding dynamic and expressive characteristics to the sound.
#
# LFO Overview:
# - Low Frequency: Operates below human hearing threshold, typically below 20 Hz.
# - Oscillator: Regularly varies over time, influencing other sound parameters.
#
# LFO Parameters:
# 1. Rate/Speed: Determines the oscillation speed. Faster rate equals rapid modulation.
# 2. Depth/Intensity: Controls the extent of the LFO's effect on the modulated parameter.
# 3. Waveform: Shapes of the wave (sine, square, triangle, etc.) affect the modulation style.
# 4. Phase: Starting point in the waveform’s cycle, useful for synchronization.
# 5. Destination: The parameter being modulated (e.g., pitch, volume, filter cutoff).
#
# LFO Uses in Synths:
# - Modulating synth parameters like pitch, amplitude, filter cutoff for effects like vibrato, tremolo, wah-wah.
# - Applying to audio effect parameters, creating dynamic effects.
# - Serving as an alternative to manual automation in DAWs.
# - Creating rhythmic elements by syncing to the track's tempo.
# - Expanding sound design possibilities with evolving textures and patterns.
#
# Advanced Techniques:
# - LFO on LFO: Complex modulations by applying an LFO to another LFO's parameters.
# - Envelope-Controlled LFOs: Using envelopes to dynamically control LFO settings.
# - MIDI Sync: Ensuring rhythmic consistency by syncing LFOs to the MIDI clock.
#
# Usage Tips:
# - Use subtlety for modulation depth.
# - Experiment with different waveforms for varied effects.
# - Consider the mix impact of LFO-modulated tracks.
# - Utilize automation for LFO parameter variation.
#
# This information provides a foundational understanding of LFOs in the context of this Synth class.

module Sidtool
  class Synth
    attr_reader :start_frame, :controls
    attr_accessor :waveform, :frequency, :pulse_width, :filter_cutoff, :filter_resonance
    attr_accessor :attack, :decay, :sustain, :release, :osc_sync, :ring_mod_effect

    # Constants for slide detection and handling
    SLIDE_THRESHOLD = 60
    SLIDE_DURATION_FRAMES = 20

    # Initialize a new Synth instance.
    # @param start_frame [Integer] The frame number where this synth instance begins.
    def initialize(start_frame)
      # The starting frame of the synth voice, used for timing control.
      @start_frame = start_frame

      # An array to store control changes for the synth parameters over time.
      @controls = []

      # Default values for various synth parameters.
      @frequency = nil
      @released_at = nil
      @waveform = :triangle
      @pulse_width = 0
      @attack = 0
      @decay = 0
      @sustain = 0
      @release = 0
      @filter_cutoff = 1024
      @filter_resonance = 8
      @osc_sync = 0
      @ring_mod_effect = 0
      @modulation = 0
      @expression = 0
      @pitch_bend = 0
    end

    # Set the frequency and handle slides if detected.
    # @param frequency [Float] The new frequency to set.
    def frequency=(frequency)
      if @frequency
        previous_midi = sid_frequency_to_nearest_midi(@frequency)
        current_midi = sid_frequency_to_nearest_midi(frequency)
        if slide_detected?(@frequency, frequency)
          handle_slide(previous_midi, current_midi)
        else
          @controls << [STATE.current_frame, current_midi] if previous_midi != current_midi
        end
      end
      @frequency = frequency
    end

    # Trigger the release of the synth, marking the beginning of the release phase.
    def release!
      return if released?

      @released_at = STATE.current_frame
      length_of_ads = (STATE.current_frame - @start_frame) / FRAMES_PER_SECOND
      @attack, @decay, @sustain_length = adjust_ads(length_of_ads)
    end

    # Check if the synth has been released.
    # @return [Boolean] True if released, false otherwise.
    def released?
      !!@released_at
    end

    # Stop the synth and calculate the release time if it hasn't been released yet.
    def stop!
      if released?
        @release = [@release, (STATE.current_frame - @released_at) / FRAMES_PER_SECOND].min
      else
        @release = 0
        release!
      end
    end

    # Convert the synth state to an array format, typically used for MIDI or other data representations.
    # @return [Array] The synth state as an array.
    def to_a
      [@start_frame, tone, @waveform, @attack.round(3), @decay.round(3), @sustain_length.round(3), @release.round(3), @controls]
    end

    # Convert the current frequency to the nearest MIDI note.
    # @return [Integer] The nearest MIDI note number.
    def tone
      sid_frequency_to_nearest_midi(@frequency)
    end

    # Set the frequency of the synth at a specific frame.
    # @param frame [Integer] The frame number to set the frequency.
    # @param frequency [Float] The frequency to set.
    def set_frequency_at_frame(frame, frequency)
      return if frame < @start_frame

      relative_frame = frame - @start_frame
      midi_note = sid_frequency_to_nearest_midi(frequency)
      @controls << [relative_frame, midi_note]
    end

    private

    # Detect if a slide is occurring between two frequencies.
    # @param old_frequency [Float] The old frequency.
    # @param new_frequency [Float] The new frequency.
    # @return [Boolean] True if a slide is detected, false otherwise.
    def slide_detected?(old_frequency, new_frequency)
      old_midi = sid_frequency_to_nearest_midi(old_frequency)
      new_midi = sid_frequency_to_nearest_midi(new_frequency)
      (new_midi - old_midi).abs > SLIDE_THRESHOLD
    end

    # Handle a slide from one MIDI note to another.
    # @param start_midi [Integer] The starting MIDI note.
    # @param end_midi [Integer] The ending MIDI note.
    def handle_slide(start_midi, end_midi)
      midi_step = (end_midi - start_midi) / SLIDE_DURATION_FRAMES.to_f
      (1..SLIDE_DURATION_FRAMES).each do |frame_offset|
        interpolated_midi = start_midi + (midi_step * frame_offset)
        @controls << [STATE.current_frame + frame_offset, interpolated_midi.round]
      end
    end

    # Adjust the ADS (Attack, Decay, Sustain) lengths based on the total length of the ADS phase.
    # @param length_of_ads [Float] The total length of the ADS phase.
    # @return [Array] Adjusted lengths of attack, decay, and sustain.
    def adjust_ads(length_of_ads)
      if length_of_ads < @attack
        [length_of_ads, 0, 0]
      elsif length_of_ads < @attack + @decay
        [@attack, length_of_ads - @attack, 0]
      else
        [@attack, @decay, length_of_ads - @attack - @decay]
      end
    end

    # Convert SID frequency to the nearest MIDI note number.
    # @param sid_frequency [Integer] The SID frequency.
    # @return [Integer] The nearest MIDI note number.
    def sid_frequency_to_nearest_midi(sid_frequency)
      actual_frequency = sid_frequency_to_actual_frequency(sid_frequency)
      nearest_tone(actual_frequency)
    end

    # Find the nearest MIDI tone for a given frequency.
    # @param frequency [Float] The frequency.
    # @return [Integer] The nearest MIDI tone.
    def nearest_tone(frequency)
      midi_tone = (12 * (Math.log(frequency * 0.0022727272727) / Math.log(2))) + 69
      midi_tone.round
    end

    # Convert SID frequency to actual frequency (in Hz).
    # @param sid_frequency [Integer] The SID frequency.
    # @return [Float] The actual frequency in Hz.
    def sid_frequency_to_actual_frequency(sid_frequency)
      (sid_frequency * (CLOCK_FREQUENCY / 16777216)).round(2)
    end

    # Other private methods for modulation, pitch bend, ADSR handling, etc., go here...
  end
end


    private

# Convert modulation parameters to MIDI controller messages
    def handle_modulation_expression
      # The SID's modulation effects can be mapped to MIDI's modulation wheel or expression controller
      [
        # Controller for Modulation Wheel (CC 01)
        [0xB0, 0x01, calculate_modulation_value(@modulation)],
        # Controller for Expression (CC 11)
        [0xB0, 0x0B, @expression]
      ]
    end

 # Convert pitch bend parameter to MIDI pitch bend messages
    def handle_pitch_bend
      # SID's pitch-related parameters can be mapped to MIDI's pitch bend
      pitch_bend_value = calculate_pitch_bend_value(@pitch_bend)
      [
        # Pitch Bend message
        [0xE0, pitch_bend_value & 0x7F, (pitch_bend_value >> 7) & 0x7F]
      ]
    end

    # Calculate modulation value for MIDI (Modulation Wheel)
    def calculate_modulation_value(modulation)
      # Map SID modulation value to MIDI (0-127). Modify this mapping as per your requirements.
      [modulation, 127].min
    end

    # Calculate pitch bend value for MIDI
    def calculate_pitch_bend_value(pitch_bend)
      # Map SID pitch bend to MIDI pitch bend range (0-16383 with 8192 as center)
      # Modify this mapping as per your requirements.
      # Example: Assuming pitch_bend range is -1 to 1
      8192 + (pitch_bend * 8192).to_i
    end

   # Convert ADSR parameters to MIDI controller messages
    def handle_attack_decay_sustain_release
      # Mapping SID's ADSR to MIDI's ADSR-like parameters
      # Note: MIDI doesn't have a direct ADSR envelope control, but we can use various controllers
      #       to simulate the effect. This is a basic mapping and might need adjustments.

      # Calculate MIDI values based on SID ADSR parameters
      attack_midi = (@attack * 127).to_i  # Scale attack to MIDI range (0-127)
      decay_midi = (@decay * 127).to_i    # Scale decay to MIDI range (0-127)
      sustain_midi = (@sustain * 127).to_i  # Scale sustain to MIDI range (0-127)
      release_midi = (@release * 127).to_i  # Scale release to MIDI range (0-127)

      # You can use MIDI control change messages (CC) for ADSR-like parameters
      # Here's an example of assigning them to specific CC numbers (adjust as needed)
      cc_attack = 1  # CC 01 for attack
      cc_decay = 2   # CC 02 for decay
      cc_sustain = 3 # CC 03 for sustain
      cc_release = 4 # CC 04 for release

      # Create MIDI controller messages for ADSR parameters
      midi_messages = [
        [0xB0, cc_attack, attack_midi],     # Controller for Attack (CC 01)
        [0xB0, cc_decay, decay_midi],       # Controller for Decay (CC 02)
        [0xB0, cc_sustain, sustain_midi],   # Controller for Sustain (CC 03)
        [0xB0, cc_release, release_midi]    # Controller for Release (CC 04)
      ]

      # Return the MIDI controller messages
      midi_messages
    end
  end
end
