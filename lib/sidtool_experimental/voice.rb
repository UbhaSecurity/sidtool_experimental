module SidtoolExperimental
  class Voice
    attr_accessor :frequency_low, :frequency_high, :pulse_low, :pulse_high
    attr_accessor :control_register, :attack_decay, :sustain_release
    attr_accessor :filter_cutoff, :filter_resonance, :filter_enabled  # New filter parameters
    attr_reader :synths

    # Define arrays to store the conversion values for attack and decay/release
    ATTACK_VALUES = [0.002, 0.008, 0.016, 0.024, 0.038, 0.056, 0.068, 0.08, 0.1, 0.25, 0.5, 0.8, 1, 3, 5, 8]
    DECAY_RELEASE_VALUES = [0.006, 0.024, 0.048, 0.072, 0.114, 0.168, 0.204, 0.24, 0.3, 0.75, 1.5, 2.4, 3, 9, 15, 24]

    # Initialize a new Voice instance with a reference to the SID chip and its voice number.
    #
    # @param sid6581 [Sid6581] Reference to the SID chip instance.
    # @param voice_number [Integer] The number of the voice on the SID chip.
    def initialize(sid6581, voice_number, state)
      @sid6581 = sid6581
      @synth = Synth.new(0, state)  # Pass the state here
      @voice_number = voice_number
      @frequency_low = @frequency_high = 0
      @pulse_low = @pulse_high = 0
      @control_register = 0
      @attack_decay = @sustain_release = 0
      @filter_cutoff = 1024
      @filter_resonance = 8
      @filter_enabled = false  # Added filter_enabled flag
      @previous_midi_note = nil
    end

    def generate_waveform(phase)
      case control_register & 0x0F # Assuming control_register holds the waveform type
      when WAVEFORM_TRIANGLE
        generate_triangle_wave(phase)
      when WAVEFORM_SAWTOOTH
        generate_sawtooth_wave(phase)
      when WAVEFORM_PULSE
        generate_pulse_wave(phase)
      when WAVEFORM_NOISE
        generate_noise_wave(phase)
      else
        0 # No waveform selected
      end
    end

    def process_adsr(sample_rate)
      # Determine the current elapsed time in seconds since the note started
      elapsed_time = (STATE.current_frame - @start_frame) / sample_rate.to_f

      case current_adsr_stage(elapsed_time)
      when :attack
        calculate_attack_amplitude(elapsed_time)
      when :decay
        calculate_decay_amplitude(elapsed_time)
      when :sustain
        calculate_sustain_amplitude
      when :release
        calculate_release_amplitude(elapsed_time)
      else
        0.0  # Return silence if no ADSR stage is active
      end
    end

    def current_adsr_stage(elapsed_time)
      if elapsed_time < @attack
        :attack
      elsif elapsed_time < @attack + @decay
        :decay
      elsif elapsed_time < @attack + @decay + @sustain_length
        :sustain
      else
        :release
      end
    end

    def calculate_attack_amplitude(elapsed_time)
      attack_duration = @attack
      if attack_duration > 0
        # Calculate the amplitude increase per second during the attack phase
        amplitude_increase_per_sec = 1.0 / attack_duration
        # Calculate the current amplitude based on elapsed time
        amplitude = elapsed_time * amplitude_increase_per_sec
        # Ensure that the amplitude doesn't exceed 1.0
        [amplitude, 1.0].min
      else
        # No attack phase, sustain amplitude is 1.0
        1.0
      end
    end

    def calculate_decay_amplitude(elapsed_time)
      decay_duration = @decay
      if decay_duration > 0
        # Calculate the amplitude decrease per second during the decay phase
        amplitude_decrease_per_sec = 1.0 / decay_duration
        # Calculate the current amplitude based on elapsed time
        amplitude = 1.0 - elapsed_time * amplitude_decrease_per_sec
        # Ensure that the amplitude doesn't go below the sustain level
        [amplitude, @sustain_level].max
      else
        # No decay phase, sustain amplitude is 1.0
        @sustain_level
      end
    end

    def calculate_sustain_amplitude
      # Sustain amplitude remains constant at the specified level
      @sustain_level
    end

    def calculate_release_amplitude(elapsed_time)
      release_duration = @release
      if release_duration > 0
        # Calculate the amplitude decrease per second during the release phase
        amplitude_decrease_per_sec = 1.0 / release_duration
        # Calculate the current amplitude based on elapsed time
        amplitude = @sustain_level - elapsed_time * amplitude_decrease_per_sec
        # Ensure that the amplitude doesn't go below 0.0
        [amplitude, 0.0].max
      else
        # No release phase, amplitude remains at the sustain level
        @sustain_level
      end
    end

    def update_from_synth(synth_params)
      # Initialize a new Synth instance if @synth is nil
      @synth ||= Synth.new(STATE.current_frame)

      # Update each parameter based on the data received from Synth
      self.frequency_low, self.frequency_high = split_frequency(synth_params[:frequency])
      self.pulse_low, self.pulse_high = split_pulse_width(synth_params[:pulse_width])
      @filter_cutoff = synth_params[:filter_cutoff]
      @filter_resonance = synth_params[:filter_resonance]
      @filter_enabled = synth_params[:filter_enabled]  # Update filter_enabled flag
      @osc_sync = synth_params[:osc_sync]
      @ring_mod_effect = synth_params[:ring_mod_effect]

      # Convert ADSR values if needed and update
      self.attack_decay = combine_attack_decay(synth_params[:attack], synth_params[:decay])
      self.sustain_release = combine_sustain_release(synth_params[:sustain], synth_params[:release])

      # Now you can call apply_lfo on the @synth object
      @synth.apply_lfo
    end

    # Apply LFO modulation to voice parameters and filter parameters
    def apply_lfo_modulation
      @synth.apply_lfo  # Apply LFO modulation to synth parameters

      # Update SID chip registers with modulated values
      @sid6581.set_frequency_low(@voice_number, @synth.frequency & 0xFF)
      @sid6581.set_frequency_high(@voice_number, (@synth.frequency >> 8) & 0xFF)
      @sid6581.set_pulse_width_low(@voice_number, @synth.pulse_width & 0xFF)
      @sid6581.set_pulse_width_high(@voice_number, (@synth.pulse_width >> 8) & 0xFF)

      # Update filter parameters with LFO modulation if filter is enabled
      modulate_filter_with_lfo if @filter_enabled
    end

    # Method to apply LFO modulation to voice parameters
    def modulate_with_lfo
      @synth.apply_lfo if @synth
      update_sid_registers
    end

    # Update properties of the current synthesizer.
    def update_synth_properties
      midi_note = frequency_to_midi(frequency)
      if midi_note != @previous_midi_note
        handle_midi_note_change(midi_note)
        @previous_midi_note = midi_note
      end

      @current_synth.waveform = waveform
      @current_synth.attack = attack
      @current_synth.decay = decay
      @current_synth.release = release
    end

    def finish_frame
      # Process this voice's contribution to the audio for this frame
      # Add the output to the SID's audio buffer
      # Note: This is just a placeholder, actual implementation will depend on SID's audio synthesis logic
      @sid6581.audio_buffer << generate_frame_output

    private

    def generate_triangle_wave(phase)
      # Triangle waveform generation logic
      # Assuming phase is a value between 0 and 1 representing the current phase position

      # Calculate the value of the triangle wave based on phase
      if phase < 0.25
        amplitude = phase * 4.0
      elsif phase < 0.75
        amplitude = 1.0 - (phase - 0.25) * 4.0
      else
        amplitude = (phase - 0.75) * 4.0 - 1.0
      end

      # Ensure the amplitude is within the -1 to 1 range
      [amplitude, -1.0].max
      [amplitude, 1.0].min
    end

    def generate_sawtooth_wave(phase)
      # Sawtooth waveform generation logic
      # Assuming phase is a value between 0 and 1 representing the current phase position

      # Calculate the value of the sawtooth wave based on phase
      amplitude = phase * 2.0 - 1.0

      # Ensure the amplitude is within the -1 to 1 range
      [amplitude, -1.0].max
      [amplitude, 1.0].min
    end

    def generate_pulse_wave(phase)
      # Pulse waveform generation logic, considering pulse width
      # Assuming phase is a value between 0 and 1 representing the current phase position
      # Assuming pulse_width is a value between 0 and 1 representing the pulse width

      pulse_width = (@pulse_low + @pulse_high * 256) / 65535.0

      # Calculate the value of the pulse wave based on phase and pulse width
      if phase < pulse_width
        amplitude = 1.0
      else
        amplitude = -1.0
      end

      amplitude
    end

    def generate_noise_wave(_phase)
      # Noise waveform generation logic
      # In a noise waveform, the value is typically random at each time step

      # You can use a pseudorandom number generator or a noise source
      # to generate random values for the noise waveform
      # Here, we'll use Ruby's built-in random number generator for simplicity

      # Generate a random value between -1.0 and 1.0
      amplitude = (rand * 2.0) - 1.0

      amplitude
    end

    # Convert a frequency to a MIDI note number.
    def frequency_to_midi(frequency)
      69 + (12 * Math.log2(frequency / 440.0)).round
    end

    # Convert a MIDI note number to a frequency.
    def midi_to_frequency(midi_note)
      440.0 * 2 ** ((midi_note - 69) / 12.0)
    end
  end
end
