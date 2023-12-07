module SidtoolExperimental
  class Synth
    attr_reader :start_frame, :controls
    attr_accessor :waveform, :frequency, :pulse_width, :filter_cutoff, :filter_resonance
    attr_accessor :attack, :decay, :sustain, :release, :osc_sync, :ring_mod_effect

    # Constants for slide detection and handling
    SLIDE_THRESHOLD = 60
    SLIDE_DURATION_FRAMES = 20
    MAX_FREQUENCY = 20000
    FRAMES_PER_SECOND = 50.0
    CLOCK_FREQUENCY = 985248.0

    # Initialize a new Synth instance.
    def initialize(start_frame)
      @start_frame = start_frame
      @controls = []
      @frequency = 0
      @pulse_width = 0
      @filter_cutoff = 1024
      @filter_resonance = 0
      @attack = 0
      @decay = 0
      @sustain = 0
      @release = 0
      initialize_lfo
    end

    def initialize_defaults
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
    end

    def initialize_lfo
      @lfo_rate = 1.0
      @lfo_depth = 0.5  # You can set the default LFO depth here or adjust it as needed
      @lfo_waveform = :sine
      @lfo_phase = 0.5
      @lfo_destination = :pitch
    end

    def apply_lfo
      modulated_value = calculate_lfo_modulation
      case @lfo_destination
      when :pitch
        self.frequency = frequency + (modulated_value || 0)
        @controls << [current_frame, frequency.round]
      when :pulse_width
      # Additional cases for different destinations...
      end
    end

    # Converts internal parameters to a standardized format for Voice
    def to_standard_format
      {
        frequency: scale_frequency(@frequency),
        pulse_width: @pulse_width,  # Assuming pulse width does not need scaling
        filter_cutoff: @filter_cutoff,
        filter_resonance: @filter_resonance,
        osc_sync: @osc_sync,
        ring_mod_effect: @ring_mod_effect,
        attack: @attack,
        decay: @decay,
        sustain: @sustain,
        release: @release
        # Add other parameters as needed
      }
    end

    # Convert SID frequency value to the nearest MIDI note.
    #
    # @param frequency [Float] The frequency.
    # @return [Integer] The nearest MIDI note number.
    def sid_frequency_to_nearest_midi(frequency)
      # Calculate the MIDI note number based on the frequency
      if frequency > 0
        # Formula to calculate MIDI note number from frequency:
        midi_note = 69 + 12 * Math.log2(frequency / 440.0)
        # Round to the nearest integer
        midi_note.round
      else
        # Handle the case where frequency is zero or negative
        0  # You can choose a default value if needed
      end
    end

    def calculate_lfo_modulation
      phase_in_radians = @lfo_phase * Math::PI / 180.0
      time = @start_frame / FRAMES_PER_SECOND.to_f

      case @lfo_waveform
      when :sine
        Math.sin(2.0 * Math::PI * @lfo_rate * time + phase_in_radians)
      when :square
        Math.sin(2.0 * Math::PI * @lfo_rate * time + phase_in_radians) >= 0 ? 1 : -1
      when :triangle
        (2 / Math::PI) * Math.asin(Math.sin(2.0 * Math::PI * @lfo_rate * time + phase_in_radians))
      # Additional waveform cases...
      end * @lfo_depth
    end

    # @param frequency [Float] The new frequency to set.
    def frequency=(frequency)
      if @frequency
        previous_midi = sid_frequency_to_actual_frequency(@frequency)
        current_midi = sid_frequency_to_actual_frequency(frequency)
        if slide_detected?(@frequency, frequency)
          handle_slide(previous_midi, current_midi)
        else
          @controls << [current_frame, current_midi]
        end
      end
      @frequency = frequency
    end

    # Convert SID frequency value to the nearest MIDI note.
    #
    # @param frequency [Float] The frequency.
    # @return [Integer] The nearest MIDI note number.
    def sid_frequency_to_nearest_midi(frequency)
      if frequency > 0
        # Formula to calculate MIDI note number from frequency:
        midi_note = 69 + 12 * Math.log2(frequency / 440.0)
        midi_note.round
      else
        0  # You can choose a default value if needed
      end
    end

    # Trigger the release of the synth, marking the beginning of the release phase.
    def release!
      return if released?
      @released_at = current_frame
      length_of_ads = (current_frame - @start_frame) / FRAMES_PER_SECOND
      @attack, @decay, @sustain_length = adjust_ads(length_of_ads)
    end

    # Check if the synth has been released.
    #
    # @return [Boolean] True if released, false otherwise.
    def released?
      !!@released_at
    end

    # Stop the synth and calculate the release time if it hasn't been released yet.
    def stop!
      if released?
        @release = [@release, (current_frame - @released_at) / FRAMES_PER_SECOND].min
      else
        @release = 0
        release!
      end
    end

    # Convert the synth state to an array format, typically used for MIDI or other data representations.
    #
    # @return [Array] The synth state as an array.
    def to_a
      [@start_frame, tone, @waveform, @attack.round(3), @decay.round(3), @sustain_length.round(3), @release.round(3), @controls]
    end

    # Convert the current frequency to the nearest MIDI note.
    #
    # @return [Integer] The nearest MIDI note number.
    def tone
      sid_frequency_to_nearest_midi(@frequency)
    end

    # Set the frequency of the synth at a specific frame.
    #
    # @param frame [Integer] The frame number to set the frequency.
    # @param frequency [Float] The frequency to set.
    def set_frequency_at_frame(frame, frequency)
      return if frame < @start_frame

      relative_frame = frame - @start_frame
      midi_note = sid_frequency_to_nearest_midi(frequency)
      @controls << [relative_frame, midi_note]
    end

    private

    def scale_frequency(frequency)
      # Ensure frequency is within the range 0 to MAX_FREQUENCY
      # If frequency is nil or negative, it defaults to 0.
      # If frequency exceeds MAX_FREQUENCY, it is set to MAX_FREQUENCY.
      [[frequency.to_i, MAX_FREQUENCY].min, 0].max
    end

    # Detect if a slide is occurring between two frequencies.
    #
    # @param old_frequency [Float] The old frequency.
    # @param new_frequency [Float] The new frequency.
    # @return [Boolean] True if a slide is detected, false otherwise.
    def slide_detected?(old_frequency, new_frequency)
      old_midi = sid_frequency_to_nearest_midi(old_frequency)
      new_midi = sid_frequency_to_nearest_midi(new_frequency)
      (new_midi - old_midi).abs > SLIDE_THRESHOLD
    end

    # Handle a slide from one MIDI note to another.
    #
    # @param start_midi [Integer] The starting MIDI note.
    # @param end_midi [Integer] The ending MIDI note.
    def handle_slide(start_midi, end_midi)
      midi_step = (end_midi - start_midi) / SLIDE_DURATION_FRAMES.to_f
      (1..SLIDE_DURATION_FRAMES).each do |frame_offset|
        interpolated_midi = start_midi + (midi_step * frame_offset)
        @controls << [current_frame + frame_offset, interpolated_midi.round]
      end
    end

    # Adjust the ADS (Attack, Decay, Sustain) lengths based on the total length of the ADS phase.
    #
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

    # Convert SID frequency value to actual frequency in Hertz.
    #
    # @param sid_frequency [Integer] The frequency value from the SID chip.
    # @return [Float] The actual frequency in Hertz.
    def sid_frequency_to_actual_frequency(sid_frequency)
      (sid_frequency * (CLOCK_FREQUENCY.to_f / 16777216)).round(2)
    end

    # Find the nearest MIDI tone for a given frequency.
    #
    # @param frequency [Float] The frequency.
    # @return [Integer] The nearest MIDI tone.
    def nearest_tone(frequency)
      midi_tone = (12 * (Math.log(frequency * 0.0022727272727) / Math.log(2))) + 69
      midi_tone.round
    end

    # Convert modulation parameters to MIDI controller messages.
    #
    # This method handles the conversion of SID's modulation effects to MIDI's modulation wheel or expression controller.
    def handle_modulation_expression
      [
        # Controller message for Modulation Wheel (CC 01).
        [0xB0, 0x01, calculate_modulation_value(@modulation)],
        # Controller message for Expression (CC 11).
        [0xB0, 0x0B, @expression]
      ]
    end

    # Convert pitch bend parameter to MIDI pitch bend messages.
    #
    # This method maps the SID's pitch-related parameters to MIDI's pitch bend.
    def handle_pitch_bend
      pitch_bend_value = calculate_pitch_bend_value(@pitch_bend)
      [
        # Pitch Bend message formatted for MIDI.
        [0xE0, pitch_bend_value & 0x7F, (pitch_bend_value >> 7) & 0x7F]
      ]
    end

    # Calculate the modulation value for MIDI (Modulation Wheel).
    #
    # @param modulation [Integer] The modulation value from the SID.
    # @return [Integer] The corresponding MIDI modulation value.
    def calculate_modulation_value(modulation)
      # Map the SID modulation value to MIDI's range (0-127).
      # Modify this mapping as per the desired effect.
      [modulation, 127].min
    end

    # Calculate the pitch bend value for MIDI.
    #
    # @param pitch_bend [Float] The pitch bend value from the SID, typically ranging from -1 to 1.
    # @return [Integer] The corresponding MIDI pitch bend value.
    def calculate_pitch_bend_value(pitch_bend)
      # Map the SID pitch bend value to MIDI's pitch bend range (0-16383 with 8192 as the center).
      # Modify this mapping based on the desired pitch bend effect.
      8192 + (pitch_bend * 8192).to_i
    end

    # Convert ADSR (Attack, Decay, Sustain, Release) parameters to MIDI controller messages.
    #
    # This method simulates ADSR envelope control using MIDI controllers, as MIDI doesn't have direct ADSR control.
    def handle_attack_decay_sustain_release
      # Scale ADSR parameters to fit the MIDI controller value range (0-127)
      attack_midi = scale_to_midi(@attack)
      decay_midi = scale_to_midi(@decay)
      sustain_midi = scale_to_midi(@sustain)
      release_midi = scale_to_midi(@release)

      # Assign ADSR parameters to specific MIDI Control Change (CC) numbers
      cc_attack = 73   # Typically CC 73 for attack
      cc_decay = 75    # Typically CC 75 for decay
      cc_sustain = 70  # Typically CC 70 for sustain
      cc_release = 72  # Typically CC 72 for release

      # Create MIDI controller messages for ADSR parameters
      midi_messages = [
        [0xB0, cc_attack, attack_midi],
        [0xB0, cc_decay, decay_midi],
        [0xB0, cc_sustain, sustain_midi],
        [0xB0, cc_release, release_midi]
      ]

      # Return the MIDI controller messages
      midi_messages
    end

    # Helper method to scale a parameter value to the MIDI range (0-127)
    def scale_to_midi(value)
      (value * 127).to_i.clamp(0, 127)
    end
  end
end
