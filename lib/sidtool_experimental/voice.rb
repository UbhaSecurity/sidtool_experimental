module SidtoolExperimental
  class Voice
    attr_accessor :frequency_low, :frequency_high, :pulse_low, :pulse_high
    attr_accessor :control_register, :attack_decay, :sustain_release
    attr_accessor :filter_cutoff, :filter_resonance  # New filter parameters
    attr_reader :synths

    # Define arrays to store the conversion values for attack and decay/release
    ATTACK_VALUES = [0.002, 0.008, 0.016, 0.024, 0.038, 0.056, 0.068, 0.08, 0.1, 0.25, 0.5, 0.8, 1, 3, 5, 8]
    DECAY_RELEASE_VALUES = [0.006, 0.024, 0.048, 0.072, 0.114, 0.168, 0.204, 0.24, 0.3, 0.75, 1.5, 2.4, 3, 9, 15, 24]

# Method to update parameters based on data from Synth
#
# @param synth_params [Hash] A hash containing parameters received from Synth.
# @option synth_params [Integer] :frequency The frequency value.
# @option synth_params [Integer] :pulse_width The pulse width value.
# @option synth_params [Integer] :filter_cutoff The filter cutoff frequency.
# @option synth_params [Integer] :filter_resonance The filter resonance value.
# @option synth_params [Boolean] :osc_sync The oscillator sync flag.
# @option synth_params [Boolean] :ring_mod_effect The ring modulation effect flag.
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
    #
    # @param sid6581 [Sid6581] Reference to the SID chip instance.
    # @param voice_number [Integer] The number of the voice on the SID chip.
    def initialize(sid6581, voice_number)
      @sid6581 = sid6581
      @voice_number = voice_number
      @frequency_low = @frequency_high = 0
      @pulse_low = @pulse_high = 0
      @control_register = 0
      @attack_decay = @sustain_release = 0
      @current_synth = nil
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

    # Handle filter modulation by LFO
    def modulate_filter_with_lfo
      @synth.apply_lfo  # Apply LFO modulation

      # Update SID chip registers with modulated filter parameters
      @sid6581.set_filter_cutoff(@voice_number, @synth.filter_cutoff & 0xFF)
      @sid6581.set_filter_resonance(@voice_number, @synth.filter_resonance & 0xFF)
    end

    # Method to apply LFO modulation to voice parameters
    def modulate_with_lfo
      @synth.apply_lfo
      update_sid_registers
    end

    # Update the SID registers based on the modulated synth parameters
    def update_sid_registers
      update_frequency_registers
      update_pulse_width_registers
      # Update other registers as needed...
    end

    # Updates the state of the voice at the end of each frame.
    def finish_frame
      update_sustain_level
      if gate
        handle_gate_on
      else
        handle_gate_off
      end
    end

    # Immediately stops the current synthesizer.
    def stop!
      @current_synth&.stop!
      @current_synth = nil
    end

    private

    # Example helper methods to split frequency and pulse width into low and high bytes
    def split_frequency(frequency)
      [frequency & 0xFF, (frequency >> 8) & 0xFF]
    end

    def split_pulse_width(pulse_width)
      [pulse_width & 0xFF, (pulse_width >> 8) & 0xFF]
    end

    # Combine attack and decay values into a single byte (if needed)
    def combine_attack_decay(attack, decay)
      # Example: pack attack and decay into a single byte
      ((attack & 0xF) << 4) | (decay & 0xF)
    end

    # Combine sustain and release values into a single byte (if needed)
    def combine_sustain_release(sustain, release)
      # Example: pack sustain and release into a single byte
      ((sustain & 0xF) << 4) | (release & 0xF)
    end

    # Update SID frequency registers for this voice
    def update_frequency_registers
      frequency = @synth.frequency
      # Split the frequency into low and high byte and update SID registers
      @sid6581.set_frequency_low(@voice_number, frequency & 0xFF)
      @sid6581.set_frequency_high(@voice_number, (frequency >> 8) & 0xFF)
    end

    # Update SID pulse width registers for this voice
    def update_pulse_width_registers
      pulse_width = @synth.pulse_width
      # Split the pulse width into low and high byte and update SID registers
      @sid6581.set_pulse_width_low(@voice_number, pulse_width & 0xFF)
      @sid6581.set_pulse_width_high(@voice_number, (pulse_width >> 8) & 0xFF)
    end

    # Determines if the gate flag is set in the control register.
    #
    # @return [Boolean] True if the gate is on, false otherwise.
    def gate
      @control_register & 1 == 1
    end

    # Calculates the frequency from the low and high byte values.
    #
    # @return [Float] The frequency value.
    def frequency
      (@frequency_high << 8) + @frequency_low
    end

    # Determines the waveform type based on the control register.
    #
    # @return [Symbol] The waveform type (:tri, :saw, :pulse, :noise).
    def waveform
      case @control_register & 0xF0
      when 0x10 then :tri
      when 0x20 then :saw
      when 0x40 then :pulse
      when 0x80 then :noise
      else
        :noise
      end
    end

    # Converts the attack value from SID format to a usable format.
    #
    # @return [Float] The converted attack value.
    def attack
      convert_attack(@attack_decay >> 4)
    end

    # Converts the decay value from SID format to a usable format.
    #
    # @return [Float] The converted decay value.
    def decay
      convert_decay_or_release(@attack_decay & 0xF)
    end

    # Converts the release value from SID format to a usable format.
    #
    # @return [Float] The converted release value.
    def release
      convert_decay_or_release(@sustain_release & 0xF)
    end

    # Updates the sustain level based on the sustain_release register.
    def update_sustain_level
      @sustain_level = @sustain_release >> 4
    end

    def handle_gate_on
      if frequency > 0 && !@current_synth
        @current_synth = Synth.new(STATE.current_frame)
        @synths << @current_synth
        update_synth_properties
      end
    end

    # Handle logic for when the gate is off.
    def handle_gate_off
      @current_synth&.release!
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

    # Handle a change in MIDI note.
    def handle_midi_note_change(midi_note)
      if slide_detected?(@previous_midi_note, midi_note)
        handle_slide(@previous_midi_note, midi_note)
      else
        @current_synth.frequency = midi_to_frequency(midi_note)
      end
    end

    # Detect if a slide is occurring between two MIDI notes.
    def slide_detected?(prev_midi_note, new_midi_note)
      (new_midi_note - prev_midi_note).abs > SLIDE_THRESHOLD
    end

    # Handle a slide between two MIDI notes.
    def handle_slide(start_midi, end_midi)
      num_frames = SLIDE_DURATION_FRAMES
      midi_increment = (end_midi - start_midi) / num_frames.to_f
      (1..num_frames).each do |i|
        midi_note = start_midi + midi_increment * i
        @current_synth.set_frequency_at_frame(STATE.current_frame + i, midi_to_frequency(midi_note.round))
      end
    end

    # Convert a MIDI note number to a frequency.
    #
    # @param midi_note [Integer] The MIDI note number.
    # @return [Float] The corresponding frequency in Hertz.
    def midi_to_frequency(midi_note)
      440.0 * 2 ** ((midi_note - 69) / 12.0)
    end

    # Convert a frequency to a MIDI note number.
    #
    # @param frequency [Float] The frequency in Hertz.
    # @return [Integer] The MIDI note number.
    def frequency_to_midi(frequency)
      69 + (12 * Math.log2(frequency / 440.0)).round
    end

    # Converts the SID's attack rate value to a corresponding time duration.
    #
    # @param attack [Integer] The SID attack rate value.
    # @return [Float] The corresponding time duration in seconds.
    def convert_attack(attack)
      raise "Unknown attack value: #{attack}" if attack < 0 || attack >= ATTACK_VALUES.length
      ATTACK_VALUES[attack]
    end

    # Converts the SID's decay or release value to a duration in seconds.
    #
    # @param decay_or_release [Integer] The SID decay or release value.
    # @return [Float] The duration in seconds.
    def convert_decay_or_release(decay_or_release)
      raise "Unknown decay or release value: #{decay_or_release}" if decay_or_release < 0 || decay_or_release >= DECAY_RELEASE_VALUES.length
      DECAY_RELEASE_VALUES[decay_or_release]
    end
  end
end
