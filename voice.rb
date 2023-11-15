module Sidtool
  class Voice
    # Accessors for various voice parameters like frequency, pulse, control registers, and ADSR values.
    attr_accessor :frequency_low, :frequency_high, :pulse_low, :pulse_high
    attr_accessor :control_register, :attack_decay, :sustain_release

    # Reader for the array of synthesizer instances used by this voice.
    attr_reader :synths

    # Initialize a new Voice instance with SID chip and voice number.
    # Initializes various parameters and sets up an array to hold synthesizer instances.
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
    end

    # Called at the end of each frame to update the state of the voice.
    def finish_frame
      if gate
        handle_gate_on
      else
        handle_gate_off
      end
    end

    # Immediately stop the current synthesizer.
    def stop!
      @current_synth&.stop!
      @current_synth = nil
    end

    private

    # Determine if the gate flag is set in the control register.
    def gate
      @control_register & 1 == 1
    end

    # Calculate the frequency from the low and high byte values.
    def frequency
      (@frequency_high << 8) + @frequency_low
    end

    # Determine the waveform type based on the control register.
    def waveform
      case @control_register & 0xF0
      when 0x10 then :tri
      when 0x20 then :saw
      when 0x40 then :pulse
      when 0x80 then :noise
      else
        STDERR.puts "Unknown waveform: #{@control_register}"
        :noise
      end
    end

    # Convert attack value from SID format to a more usable format.
    def attack
      convert_attack(@attack_decay >> 4)
    end

    # Convert decay value from SID format to a more usable format.
    def decay
      convert_decay_or_release(@attack_decay & 0xF)
    end

    # Convert release value from SID format to a more usable format.
    def release
      convert_decay_or_release(@sustain_release & 0xF)
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

    # Conversion function for attack parameter based on SID 6581 specifications.
    def convert_attack(attack)
      # Implement conversion logic here...
      # ...
    end

    # Conversion function for decay and release parameters based on SID 6581 specifications.
    def convert_decay_or_release(decay_or_release)
      # Implement conversion logic here...
      # ...
    end
 
def convert_attack(attack)
  # Converts the SID's attack rate value (0-15) to a corresponding time duration.
  # These durations determine how quickly the sound reaches its peak amplitude from silence.
  # The values provided here are based on the SID 6581 chip's specifications and represent
  # the duration of the attack phase in seconds.
  #
  # attack - The attack rate value from the SID chip, ranging from 0 to 15.
  #
  # The method returns a float representing the duration in seconds for the attack phase.
  # For example, a value of 0.002 means the attack phase will last 2 milliseconds.
  #
  # It is important to adjust these values to match the real behavior of the SID model being emulated,
  # as different models or revisions of the SID chip might have slightly different ADSR timings.
  #
  # The method raises an exception if an unknown attack value is provided, ensuring that
  # only valid SID attack values are processed.
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


    def convert_decay_or_release(decay_or_release)
      # Conversion based on SID 6581 specifications
      # Implement SID's ADSR conversion for decay and release
      case decay_or_release
      when 0 then 0.006
      when 1 then 0.024
      when 2 then 0.048
      when 3 then 0.072
      when 4 then 0.114
      when 5 then 0.168
      when 6 then 0.204
      when 7 then 0.240
      when 8 then 0.3
      when 9 then 0.75
      when 10 then 1.5
      when 11 then 2.4
      when 12 then 3
      when 13 then 9
      when 14 then 15
      when 15 then 24
      else raise "Unknown value: #{decay_or_release}"
      end
    end
  end
end
