require 'wav-file'
module SidtoolExperimental
  class Sid6581
    attr_accessor :state

    # Define waveform constants for easy reference
    WAVEFORM_TRIANGLE = 0x01
    WAVEFORM_SAWTOOTH = 0x02
    WAVEFORM_PULSE = 0x04
    WAVEFORM_NOISE = 0x08

    # Define register addresses for each voice
    FREQ_LO = [0xD400, 0xD407, 0xD40E]
    FREQ_HI = [0xD401, 0xD408, 0xD40F]
    PW_LO   = [0xD402, 0xD409, 0xD410]
    PW_HI   = [0xD403, 0xD40A, 0xD411]
    CR      = [0xD404, 0xD40B, 0xD412]
    AD      = [0xD405, 0xD40C, 0xD413]
    SR      = [0xD406, 0xD40D, 0xD414]

    # Global filter and volume register addresses
    FC_LO      = 0xD415
    FC_HI      = 0xD416
    RES_FILT   = 0xD417
    MODE_VOL   = 0xD418
    POTX       = 0xD419
    POTY       = 0xD41A
    OSC3       = 0xD41B
    ENV3       = 0xD41C

    def initialize(memory:)
      @memory = memory
      @voices = []
      @global_filter_cutoff = 0
      @global_filter_resonance = 0
      @global_volume = 0
      @audio_buffer = []  # Initialize the audio buffer
    end

    def create_voices
      3.times do |voice_index|
        @voices << Voice.new(@memory, @state, voice_index)
      end
    end

    # Apply LFO modulation to all voices
    def apply_lfo_to_voices
      @voices.each do |voice|
        voice.modulate_with_lfo  # Use LFO settings from the Synth class
      end
    end

    def update_register(register_index, value)
      # Logic to update SID register based on index and value
      case register_index
      when 0..28 # SID has 29 registers (0 to 28)
        # Update the corresponding SID register
        # Example: @voices[voice_index].set_frequency_low(value) for a frequency low register
      else
        raise "Invalid SID register index: #{register_index}"
      end
    end

    def handle_sid_register_error(error_message)
      # You can customize this error handling logic based on your requirements.
      # For example, you can raise an exception with the error message.
      raise StandardError, "SID Register Error: #{error_message}"
    end

    # Set the low byte of the frequency for a specific voice
    def set_frequency_low(voice_number, value)
      freq_lo_address = calculate_register_address('FREQ_LO', voice_number)
      write_register(freq_lo_address, value)
    end

    # Set the high byte of the frequency for a specific voice
    def set_frequency_high(voice_number, value)
      freq_hi_address = calculate_register_address('FREQ_HI', voice_number)
      write_register(freq_hi_address, value)
    end

    # Set the low byte of the pulse width for a specific voice
    def set_pulse_width_low(voice_number, value)
      pw_lo_address = calculate_register_address('PW_LO', voice_number)
      write_register(pw_lo_address, value)
    end

    # Set the high byte of the pulse width for a specific voice
    def set_pulse_width_high(voice_number, value)
      pw_hi_address = calculate_register_address('PW_HI', voice_number)
      write_register(pw_hi_address, value)
    end

    # Update the SID chip's state including LFO modulation
    def update_sid_state
      apply_lfo_to_voices
      update_registers
      generate_sound
    end

    # Read the value from a SID register
    def read_sid_register(address)
      case address
      when *FREQ_LO
        voice_index = FREQ_LO.index(address)
        @voices[voice_index].frequency_low
      when *FREQ_HI
        voice_index = FREQ_HI.index(address)
        @voices[voice_index].frequency_high
      when *PW_LO
        voice_index = PW_LO.index(address)
        @voices[voice_index].pulse_low
      when *PW_HI
        voice_index = PW_HI.index(address)
        @voices[voice_index].pulse_high
      when *CR
        voice_index = CR.index(address)
        @voices[voice_index].control_register
      when *AD
        voice_index = AD.index(address)
        @voices[voice_index].attack_decay
      when *SR
        voice_index = SR.index(address)
        @voices[voice_index].sustain_release
      when FC_LO
        @global_filter_cutoff & 0x00FF
      when FC_HI
        (@global_filter_cutoff >> 8) & 0x00FF
      when RES_FILT
        @global_filter_resonance
      when MODE_VOL
        @global_volume
      else
        raise "Unsupported SID register address for read: #{address}"
      end
    end

    private

    # Update all registers based on current voice state
    def update_registers
      @voices.each_with_index do |voice, index|
        set_frequency_low(index, voice.frequency_low)
        set_frequency_high(index, voice.frequency_high)
        set_pulse_width_low(index, voice.pulse_low)
        set_pulse_width_high(index, voice.pulse_high)
        # Update other registers as needed
      end
    end

    # Calculate the register address for a given voice and type
    def calculate_register_address(type, voice_number)
      case type
      when 'FREQ_LO'
        return FREQ_LO[voice_number]
      when 'FREQ_HI'
        return FREQ_HI[voice_number]
      when 'PW_LO'
        return PW_LO[voice_number]
      when 'PW_HI'
        return PW_HI[voice_number]
      when 'CR'
        return CR[voice_number]
      when 'AD'
        return AD[voice_number]
      when 'SR'
        return SR[voice_number]
      when 'FC_LO'
        return FC_LO
      when 'FC_HI'
        return FC_HI
      when 'RES_FILT'
        return RES_FILT
      when 'MODE_VOL'
        return MODE_VOL
      else
        handle_sid_register_error("Unsupported SID register type: #{type}")
        return nil
      end
    end

    # Write a value to a SID register
    def write_register(address, value)
      case address
      when *FREQ_LO
        voice_index = FREQ_LO.index(address)
        @voices[voice_index].set_frequency_low(value)
      when *FREQ_HI
        voice_index = FREQ_HI.index(address)
        @voices[voice_index].set_frequency_high(value)
      when *PW_LO
        voice_index = PW_LO.index(address)
        @voices[voice_index].set_pulse_width_low(value)
      when *PW_HI
        voice_index = PW_HI.index(address)
        @voices[voice_index].set_pulse_width_high(value)
      when *CR
        voice_index = CR.index(address)
        @voices[voice_index].set_control_register(value)
      when *AD
        voice_index = AD.index(address)
        @voices[voice_index].set_attack_decay(value)
      when *SR
        voice_index = SR.index(address)
        @voices[voice_index].set_sustain_release(value)
      when FC_LO
        @global_filter_cutoff = (@global_filter_cutoff & 0xFF00) | value
      when FC_HI
        @global_filter_cutoff = (@global_filter_cutoff & 0x00FF) | (value << 8)
      when RES_FILT
        @global_filter_resonance = value
      when MODE_VOL
        @global_volume = value
      else
        raise "Unsupported SID register address: #{address}"
      end
    end

    def generate_sound
      sample_rate = AUDIO_SAMPLE_RATE
      @voices.each do |voice|
        voice.finish_frame
      end

      # Add the mixed output of this frame to the audio buffer
      process_audio(sample_rate).each do |sample|
        @audio_buffer << sample
      end

      # Optionally, handle the buffer size to avoid excessive memory usage
      if @audio_buffer.size > MAX_BUFFER_SIZE
        output_sound  # Output the buffer to a file or audio device
        @audio_buffer.clear  # Clear the buffer after outputting
      end
    end

      # Mix the outputs from all voices
      final_output = mix_voices(mixed_output)

      # Apply global filters and volume adjustment
      processed_output = apply_global_effects(final_output)

      # Return or store the processed audio output
      return processed_output # or store it in an audio buffer
    end

    def mix_voices(voice_outputs)
      # Implement the logic to mix voice outputs
      # For example, calculate the average or sum of the outputs
      voice_outputs.reduce(:+) # Simple sum of outputs
    end

    def output_sound(filename = "output.wav")
      format = WavFile::Format.new(:mono, :pcm_16, AUDIO_SAMPLE_RATE, @audio_buffer.size)
      data_chunk = WavFile::DataChunk.new(@audio_buffer.pack('s*')) # 's*' for 16-bit signed PCM data

      File.open(filename, "wb") do |file|
        WavFile.write(file, format, [data_chunk])
      end
    end

    def apply_global_effects(audio_signal)
      # Apply global filters and volume adjustments
      filtered_signal = apply_global_filter(audio_signal)
      volume_adjusted_signal = filtered_signal * @global_volume
      volume_adjusted_signal
    end

    def apply_global_filter(audio_signal)
      # Assuming @global_filter_cutoff is the cutoff frequency and it's already scaled appropriately
      cutoff_frequency = @global_filter_cutoff
      resonance = @global_filter_resonance

      # Initialize filter state variables if they don't exist
      @filter_state ||= { last_output: 0.0, last_input: 0.0 }

      # Calculate filter coefficients
      dt = 1.0 / AUDIO_SAMPLE_RATE
      rc = 1.0 / (2 * Math::PI * cutoff_frequency)
      alpha = dt / (rc + dt)

      # Apply the filter to the audio signal
      filtered_signal = audio_signal.map do |sample|
        low_pass = @filter_state[:last_output] + alpha * (sample - @filter_state[:last_output])
        band_pass = (sample - @filter_state[:last_input]) - low_pass
        high_pass = sample - low_pass - resonance * band_pass

        # Update filter state
        @filter_state[:last_output] = low_pass
        @filter_state[:last_input] = sample

        # Depending on your requirement, return low_pass, band_pass, or high_pass
        low_pass # This line can be changed to select the filter type
      end

      filtered_signal
    end
  end
