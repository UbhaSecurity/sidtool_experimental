require_relative 'WaveformGenerator'

module SidtoolExperimental
  class Voice
    attr_accessor :frequency_low, :frequency_high, :pulse_low, :pulse_high
    attr_accessor :control_register, :attack_decay, :sustain_release
    attr_accessor :filter_cutoff, :filter_resonance, :filter_enabled  # New filter parameters
    attr_reader :synths

    # Define arrays to store the conversion values for attack and decay/release
    ATTACK_VALUES = [0.002, 0.008, 0.016, 0.024, 0.038, 0.056, 0.068, 0.08, 0.1, 0.25, 0.5, 0.8, 1, 3, 5, 8]
    DECAY_RELEASE_VALUES = [0.006, 0.024, 0.048, 0.072, 0.114, 0.168, 0.204, 0.24, 0.3, 0.75, 1.5, 2.4, 3, 9, 15, 24]
    LFSR_STATE_BITS = 23
    DEFAULT_MIDI_NOTE = 60 

    # Initialize a new Voice instance with a reference to the SID chip and its voice number.
    #
    # @param sid6581 [Sid6581] Reference to the SID chip instance.
    # @param voice_number [Integer] The number of the voice on the SID chip.
    def initialize(sid6581, voice_number)
      @sid6581 = sid6581
      @synth = Synth.new(0)
      @current_synth = Synth.new(@synth.start_frame)
      @synth.waveform = :triangle
      @waveform = :triangle
      @voice_number = voice_number
      @frequency_low = @frequency_high = 0
      @pulse_low = @pulse_high = 0
      @control_register = 0
      @attack_decay = @sustain_release = 0
      @filter_cutoff = 1024
      @filter_resonance = 8
      @filter_enabled = false
      @previous_midi_note = nil
      @lfsr_state = 0b10101010101010101010101
    end

    def generate_waveform(phase)
      case control_register & 0x0F
      when WaveformGenerator::WAVEFORM_TRIANGLE
        WaveformGenerator.generate_triangle_wave(phase)
      when WaveformGenerator::WAVEFORM_SAWTOOTH
        WaveformGenerator.generate_sawtooth_wave(phase)
      when WaveformGenerator::WAVEFORM_PULSE
        pulse_width = # Define pulse_width based on your application logic
        WaveformGenerator.generate_pulse_wave(phase, pulse_width)
      when WaveformGenerator::WAVEFORM_NOISE
        @lfsr_state, noise = WaveformGenerator.generate_noise_wave(@lfsr_state)
        noise
      else
        0.0 # No waveform selected
      end
    end

    def process_adsr(sample_rate)
      # Determine the current elapsed time in seconds since the note started
      elapsed_time = (current_frame - @start_frame) / sample_rate.to_f

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

    def apply_lfo_modulation
      @synth.apply_lfo

      @sid6581.set_frequency_low(@voice_number, (calculate_frequency_hz & 0xFF))
      @sid6581.set_frequency_high(@voice_number, ((calculate_frequency_hz >> 8) & 0xFF))

      modulate_filter_with_lfo if @filter_enabled
    end

   def modulate_with_lfo
  # Add debugging statements to check variable values
  puts "Debug: waveform=#{@waveform.inspect}" if defined?(@waveform)
  puts "Debug: @current_synth=#{@current_synth.inspect}" if defined?(@current_synth)

  # Set the waveform attribute of @current_synth if @waveform is defined
@current_synth.waveform = @waveform if @waveform

  # Continue with the rest of the method...
  @synth.apply_lfo if @synth
  update_synth_properties
end

def update_synth_properties
  # Calculate the MIDI note from the current frequency
  midi_note = frequency_to_midi(calculate_frequency_hz)

  # Handle MIDI note change if necessary
  if midi_note != @previous_midi_note
    handle_midi_note_change(midi_note)
    @previous_midi_note = midi_note
  end

  # Ensure @current_synth is initialized before updating its properties
  if @current_synth
    @current_synth.waveform = @waveform if @waveform
    @current_synth.attack = @attack if @attack
    @current_synth.decay = @decay if @decay
    @current_synth.release = @release if @release
  end
end

def finish_frame
  # Process this voice's contribution to the audio for this frame
  # Add the output to the SID's audio buffer
  # Note: This is just a placeholder, actual implementation will depend on SID's audio synthesis logic

  # Check if @sid6581 is properly initialized and accessible
  if @sid6581
    # Invoke the generate_frame_output method
    frame_output = @sid6581.generate_frame_output

    # Check if frame_output is not nil or empty
    if frame_output
      # Append the output to the audio buffer
      @sid6581.audio_buffer << frame_output
    else
      # Handle the case where generate_frame_output didn't return valid data
      # You can log an error or take appropriate action here
    end
  else
    # Handle the case where @sid6581 is not properly initialized
    # You can raise an exception or log an error
  end
end

 def oscillator_bit_19_high?
      # Implement the logic to check if oscillator bit 19 is high
      bit_19 = (@lfsr_state >> 19) & 0x01
      bit_19 == 1
    end

 def generate_frame_output
      current_time = @state.current_frame.to_f / AUDIO_SAMPLE_RATE
      frequency_hz = calculate_frequency_hz # Updated this line
      phase = (current_time * frequency_hz) % 1.0


    # Generate the waveform sample based on the current phase
    waveform_sample = generate_waveform(phase) # Implement waveform generation (e.g., triangle, sawtooth, pulse, noise)

    # Apply the ADSR envelope to the waveform sample
    adsr_amplitude = process_adsr(@c64emulator.current_frame) # Implement ADSR processing

    # Combine the waveform sample with the ADSR envelope
    final_sample = waveform_sample * adsr_amplitude

    # Return the final audio sample for this frame
    final_sample
  end

  def calculate_phase(current_frame, audio_sample_rate)
      # Calculate time in seconds using current_frame and audio_sample_rate
      current_time = current_frame.to_f / audio_sample_rate.to_f

      # Calculate phase
      # Phase is the fractional part of the time multiplied by frequency
      phase = (current_time * calculate_frequency_hz) % 1.0 # Updated this line

      phase
    end

def calculate_frequency_hz
  # Convert frequency_low and frequency_high to a 16-bit value
  frequency_value = (@frequency_high << 8) | @frequency_low

  # Calculate frequency in Hertz using the formula
  frequency_hz = frequency_value * 0.0596

  frequency_hz
end

    private



# Method to select the MSB of the oscillator based on the waveform selector
def select_oscillator_msb(oscillator_value)
  # Check if the sawtooth waveform is selected (bit 4 of Control Register)
  if (@control_register & 0x10) != 0
    # Invert the MSB for the sawtooth waveform
    oscillator_msb = ~oscillator_value[11]
  else
    # For other waveforms, use the MSB directly
    oscillator_msb = oscillator_value[11]
  end

  oscillator_msb
end

# Method to apply ring modulation effect
def apply_ring_modulation(oscillator_msb, voice_number)
  # Calculate the MSB of the ring modulating voice's oscillator
  modulating_oscillator_msb = get_ring_modulating_oscillator_msb(voice_number)

  # XOR the MSBs to apply ring modulation
  oscillator_msb ^= modulating_oscillator_msb

  oscillator_msb
end

# Method to get the MSB of the ring modulating voice's oscillator
def get_ring_modulating_oscillator_msb(modulating_voice_number)
  # Implement logic to get the MSB of the modulating voice's oscillator
  # This may involve accessing the corresponding voice's oscillator MSB
  # Return the MSB value
end

# Method to calculate the XOR logic for each of the 11 bits
def calculate_triangle_bits(oscillator_value, oscillator_msb)
  triangle_bits = Array.new(11)

  (0..10).each do |bit|
    bit_x = oscillator_value[bit]
    tri_xor = (~oscillator_value & oscillator_msb) | (oscillator_value & ~oscillator_msb)
    triangle_bits[bit] = tri_xor ^ bit_x
  end

  triangle_bits
end

# Method to combine the 11 bits to form the triangle waveform
def combine_triangle_bits(triangle_bits)
  triangle_waveform = 0.0

  (0..10).each do |bit|
    triangle_waveform += triangle_bits[bit] * (2**bit)
  end

  triangle_waveform
end

def get_ring_modulating_oscillator_msb(modulating_voice_number)
  # Determine the oscillator value (upper 12 bits) of the modulating voice
  modulating_oscillator_value = get_modulating_oscillator_value(modulating_voice_number)

  # Determine the MSB of the modulating voice's oscillator
  modulating_oscillator_msb = calculate_modulating_oscillator_msb(modulating_oscillator_value)

  modulating_oscillator_msb
end

# Method to get the oscillator value (upper 12 bits) of the modulating voice
def get_modulating_oscillator_value(modulating_voice_number)
  # Implement logic to retrieve the oscillator value of the modulating voice
  # This may involve accessing the corresponding voice's oscillator registers
  # Return the oscillator value
end

# Method to calculate the MSB of the modulating voice's oscillator
def calculate_modulating_oscillator_msb(modulating_oscillator_value)
  # Implement the XOR logic as described in the technical details
  # to calculate the MSB of the modulating voice's oscillator
  tri_xor = (~modulating_oscillator_value & @oscillator_msb) | (modulating_oscillator_value & ~@oscillator_msb)
  modulating_oscillator_msb = tri_xor ^ modulating_oscillator_value[11]

  modulating_oscillator_msb
end
      

  # Helper method to get the MSB of the ring modulating voice's oscillator
  def get_ring_modulating_oscillator_msb(modulating_voice_number)
    # Implement the logic to retrieve the MSB of the modulating voice's oscillator
    # This logic was described in a previous response
    # Return the MSB value
  end



# Method to calculate the Pulse Width value from PulseWidth register bits
def calculate_pulse_width
  # Extract the low 8 bits and high 4 bits from the PulseWidth register
  low_bits = (@pulse_low >> 3) & 0xFF
  high_bits = (@pulse_high >> 4) & 0x0F

  # Calculate the 12-bit Pulse Width value
  pulse_width = (high_bits << 8) | low_bits

  pulse_width
end

 
def handle_midi_note_change(new_midi_note)
  # Calculate the new frequency in Hertz based on the new MIDI note
  new_frequency_hz = midi_to_frequency(new_midi_note)

  # Your custom logic here
  # For example, you can print the new frequency:
  puts "New Frequency (Hz): #{new_frequency_hz}"

  # You can handle the new frequency as needed in your custom logic
end


def frequency_to_midi(frequency)
      if frequency <= 0.0
        # Handle the case where frequency is zero or negative
        return DEFAULT_MIDI_NOTE
      else
        return 69 + (12 * Math.log2(frequency / 440.0)).round
      end
    end


  # Convert a MIDI note number to a frequency.
  def midi_to_frequency(midi_note)
    440.0 * 2 ** ((midi_note - 69) / 12.0)
  end

  # Clock the LFSR by one step
    def clock_lfsr
      bit0 = (@lfsr_state >> 0) & 0x01
      bit17 = (@lfsr_state >> 17) & 0x01
      bit22 = (@lfsr_state >> 22) & 0x01

      # Calculate the new bit0 value based on the provided logic
      new_bit0 = (bit17 ^ (bit0 | bit22)) & 0x01

      # Shift the LFSR one bit to the right
      @lfsr_state >>= 1

      # Set the new bit0 value in the LFSR
      @lfsr_state |= (new_bit0 << (LFSR_STATE_BITS - 1))
    end

  # Invert the bits of a given value
  def invert_bits(value)
    (~value) & ((1 << LFSR_STATE_BITS) - 1)
  end
  end
end
