module Sidtool
  class Voice
    attr_accessor :frequency_low, :frequency_high, :pulse_low, :pulse_high
    attr_accessor :control_register, :attack_decay, :sustain_release
    attr_accessor :filter_cutoff, :filter_resonance  # New filter parameters
    attr_reader :synths

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
      @synths = []
      @previous_midi_note = nil

      @filter_cutoff = 1024          # Initial filter cutoff frequency
      @filter_resonance = 8          # Initial filter resonance
    end

    def modulate_and_update
      @synth.apply_lfo  # Apply LFO modulation

      # Update SID chip registers with modulated values
      @sid6581.set_frequency_low(@voice_number, @synth.frequency & 0xFF)
      @sid6581.set_frequency_high(@voice_number, (@synth.frequency >> 8) & 0xFF)
      @sid6581.set_pulse_width_low(@voice_number, @synth.pulse_width & 0xFF)
      @sid6581.set_pulse_width_high(@voice_number, (@synth.pulse_width >> 8) & 0xFF)

      # Update filter parameters
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
    # @return [Boolean] True if the gate is on, false otherwise.
    def gate
      @control_register & 1 == 1
    end

    # Calculates the frequency from the low and high byte values.
    # @return [Float] The frequency value.
    def frequency
      (@frequency_high << 8) + @frequency_low
    end

    # Determines the waveform type based on the control register.
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
    # @return [Float] The converted attack value.
    def attack
      convert_attack(@attack_decay >> 4)
    end

    # Converts the decay value from SID format to a usable format.
    # @return [Float] The converted decay value.
    def decay
      convert_decay_or_release(@attack_decay & 0xF)
    end

    # Converts the release value from SID format to a usable format.
    # @return [Float] The converted release value.
    def release
      convert_decay_or_release(@sustain_release & 0xF)
    end

    # Updates the sustain level based on the sustain_release register.
    def update_sustain_level
      @sustain_level = @sustain_release >> 4
    end

    # Handle logic for when the gate is on.
    def handle_gate_on
      if @current_synth&.released?
        @current_synth.stop!
        @current_synth = nil
      end

      if frequency > 0
        if !@current_synth
          @current_synth = Synth.new(STATE.current_frame)
          @synths << @current_synth
          @previous_midi_note = nil
        end
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
    def midi_to_frequency(midi_note)
      440 * 2 ** ((midi_note - 69) / 12.0)
    end

    # Convert a frequency to a MIDI note number.
    def frequency_to_midi(frequency)
      midi_note = 69 + 12 * Math.log2(frequency / 440.0)
      midi_note.round
    end

    # Converts the SID's attack rate value to a corresponding time duration.
    def convert_attack(attack)
      case attack
      when 0 then 0.002  # Fastest attack, 2 milliseconds
      when 1 then 0.008
      when 2 then 0.016
      when 3 then 0.024
      when 4 then 0.038
      when 5 then 0.056
      when 6 then 0.068
      when 7 then 0.08
      when 8 then 0.1   # 100 milliseconds
      when 9 then 0.25  # Quarter of a second
      when 10 then 0.5  # Half a second
      when 11 then 0.8
      when 12 then 1    # One second
      when 13 then 3    # Three seconds
      when 14 then 5    # Five seconds
      when 15 then 8    # Slowest attack, eight seconds
      else
        raise "Unknown attack value: #{attack}"
      end
    end

    # Converts the SID's decay or release value to a duration in seconds.
    def convert_decay_or_release(decay_or_release)
      case decay_or_release
      when 0 then 0.006  # 6 milliseconds
      when 1 then 0.024
      when 2 then 0.048
      when 3 then 0.072
      when 4 then 0.114
      when 5 then 0.168
      when 6 then 0.204
      when 7 then 0.240
      when 8 then 0.3   # 300 milliseconds
      when 9 then 0.75  # 750 milliseconds
      when 10 then 1.5  # 1.5 seconds
      when 11 then 2.4
      when 12 then 3    # 3 seconds
      when 13 then 9
      when 14 then 15
      when 15 then 24   # 24 seconds, the longest duration
      else
        raise "Unknown decay or release value: #{decay_or_release}"
      end
    end
  end
end
