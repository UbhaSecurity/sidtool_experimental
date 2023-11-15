module Sidtool
  class Synth
    attr_reader :start_frame, :controls
    attr_accessor :waveform, :frequency, :pulse_width, :filter_cutoff, :filter_resonance
    attr_accessor :attack, :decay, :sustain, :release, :osc_sync, :ring_mod_effect

    SLIDE_THRESHOLD = 60
    SLIDE_DURATION_FRAMES = 20

    def initialize(start_frame)
      @start_frame = start_frame
      @controls = []
      @frequency = nil
      @released_at = nil
      @waveform = :triangle
      @pulse_width = 0
      @attack = 0
      @decay = 0
      @sustain = 0
      @release = 0
      @filter_cutoff = 1024  # Default middle value for the SID filter cutoff
      @filter_resonance = 8  # Default middle value for the SID filter resonance
      @osc_sync = 0
      @ring_mod_effect = 0
    end

    def frequency=(frequency)
      if @frequency
        previous_midi, current_midi = sid_frequency_to_nearest_midi(@frequency), sid_frequency_to_nearest_midi(frequency)
        if slide_detected?(@frequency, frequency)
          handle_slide(previous_midi, current_midi)
        else
          @controls << [STATE.current_frame, current_midi] if previous_midi != current_midi
        end
      end
      @frequency = frequency
    end

    def release!
      return if released?

      @released_at = STATE.current_frame
      length_of_ads = (STATE.current_frame - @start_frame) / FRAMES_PER_SECOND
      @attack, @decay, @sustain_length = adjust_ads(length_of_ads)
    end

    def released?
      !!@released_at
    end

    def stop!
      if released?
        @release = [@release, (STATE.current_frame - @released_at) / FRAMES_PER_SECOND].min
      else
        @release = 0
        release!
      end
    end

    def to_a
      [@start_frame, tone, @waveform, @attack.round(3), @decay.round(3), @sustain_length.round(3), @release.round(3), @controls]
    end

    def tone
      sid_frequency_to_nearest_midi(@frequency)
    end

    def set_frequency_at_frame(frame, frequency)
      return if frame < @start_frame

      relative_frame = frame - @start_frame
      midi_note = sid_frequency_to_nearest_midi(frequency)
      @controls << [relative_frame, midi_note]
    end

    private

    def slide_detected?(old_frequency, new_frequency)
      old_midi, new_midi = sid_frequency_to_nearest_midi(old_frequency), sid_frequency_to_nearest_midi(new_frequency)
      (new_midi - old_midi).abs > SLIDE_THRESHOLD
    end

    def handle_slide(start_midi, end_midi)
      midi_step = (end_midi - start_midi) / SLIDE_DURATION_FRAMES.to_f
      (1..SLIDE_DURATION_FRAMES).each do |frame_offset|
        interpolated_midi = start_midi + (midi_step * frame_offset)
        @controls << [STATE.current_frame + frame_offset, interpolated_midi.round]
      end
    end

    def adjust_ads(length_of_ads)
      if length_of_ads < @attack
        [length_of_ads, 0, 0]
      elsif length_of_ads < @attack + @decay
        [@attack, length_of_ads - @attack, 0]
      else
        [@attack, @decay, length_of_ads - @attack - @decay]
      end
    end

    def sid_frequency_to_nearest_midi(sid_frequency)
      actual_frequency = sid_frequency_to_actual_frequency(sid_frequency)
      nearest_tone(actual_frequency)
    end

    def nearest_tone(frequency)
      midi_tone = (12 * (Math.log(frequency * 0.0022727272727) / Math.log(2))) + 69
      midi_tone.round
    end

    def sid_frequency_to_actual_frequency(sid_frequency)
      (sid_frequency * (CLOCK_FREQUENCY / 16777216)).round(2)
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
