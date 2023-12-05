module SidtoolExperimental
  class Voice
    attr_accessor :frequency_low, :frequency_high, :pulse_low, :pulse_high
    attr_accessor :control_register, :attack_decay, :sustain_release
    attr_accessor :filter_cutoff, :filter_resonance  # New filter parameters
    attr_reader :synths

    # Define arrays to store the conversion values for attack and decay/release
    ATTACK_VALUES = [0.002, 0.008, 0.016, 0.024, 0.038, 0.056, 0.068, 0.08, 0.1, 0.25, 0.5, 0.8, 1, 3, 5, 8]
    DECAY_RELEASE_VALUES = [0.006, 0.024, 0.048, 0.072, 0.114, 0.168, 0.204, 0.24, 0.3, 0.75, 1.5, 2.4, 3, 9, 15, 24]

    def update_from_synth(synth_params)
      # Initialize a new Synth instance if @synth is nil
      @synth ||= Synth.new(STATE.current_frame)

      # Update each parameter based on the data received from Synth
      self.frequency_low, self.frequency_high = split_frequency(synth_params[:frequency])
      self.pulse_low, self.pulse_high = split_pulse_width(synth_params[:pulse_width])
      @filter_cutoff = synth_params[:filter_cutoff]
      @filter_resonance = synth_params[:filter_resonance]
      @osc_sync = synth_params[:osc_sync]
      @ring_mod_effect = synth_params[:ring_mod_effect]

      # Convert ADSR values if needed and update
      self.attack_decay = combine_attack_decay(synth_params[:attack], synth_params[:decay])
      self.sustain_release = combine_sustain_release(synth_params[:sustain], synth_params[:release])

      # Now you can call apply_lfo on the @synth object
      @synth.apply_lfo
    end

    # Initialize a new Voice instance with a reference to the SID chip and its voice number.
    def initialize(sid6581, voice_number)
      @sid6581 = sid6581
      @voice_number = voice_number
      @frequency_low = @frequency_high = 0
      @pulse_low = @pulse_high = 0
      @control_register = 0
      @attack_decay = @sustain_release = 0
      @current_synth = Synth.new(STATE.current_frame) # Initialize @synth here
      @previous_midi_note = nil
      @filter_cutoff = 1024
      @filter_resonance = 8
      @synths = [] # Ensure this is just an empty array without creating new Synth instances here
    end

    # Apply LFO modulation to voice parameters and filter parameters
    def apply_lfo_modulation
      @synth.apply_lfo  # Apply LFO modulation to synth parameters

      # Update SID chip registers with modulated values
      @sid6581.set_frequency_low(@voice_number, @synth.frequency & 0xFF)
      @sid6581.set_frequency_high(@voice_number, (@synth.frequency >> 8) & 0xFF)
      @sid6581.set_pulse_width_low(@voice_number, @synth.pulse_width & 0xFF)
      @sid6581.set_pulse_width_high(@voice_number, (@synth.pulse_width >> 8) & 0xFF)

      # Update filter parameters with LFO modulation
      modulate_filter_with_lfo
    end

    # ...

    # Method to apply LFO modulation to voice parameters
    def modulate_with_lfo
      @synth.apply_lfo
      update_sid_registers
    end

    # ...

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

    # ...

    private

    # ...

    # Convert a frequency to a MIDI note number.
    def frequency_to_midi(frequency)
      69 + (12 * Math.log2(frequency / 440.0)).round
    end

    # Convert a MIDI note number to a frequency.
    def midi_to_frequency(midi_note)
      440.0 * 2 ** ((midi_note - 69) / 12.0)
    end

    # ...
  end
end
