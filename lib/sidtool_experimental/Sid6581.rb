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
      @voices << Voice.new(@memory, @state, voice_index)
      @global_filter_cutoff = 0
      @global_filter_resonance = 0
      @global_volume = 0
    end

    # Apply LFO modulation to all voices
    def apply_lfo_to_voices
      @voices.each do |voice|
        voice.modulate_with_lfo  # Use LFO settings from the Synth class
      end
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

    # Generate sound for each voice
    def generate_sound
      @voices.each do |voice|
        voice.finish_frame  # Finish processing the current frame for each voice
        # Additional sound generation logic can be added here
      end
    end

    def process_audio(sample_rate)
      @voices.each do |voice|
        phase = calculate_phase(voice, sample_rate)
        waveform_output = voice.generate_waveform(phase)
        adsr_output = process_adsr(voice, sample_rate)
        final_output = waveform_output * adsr_output
        # Further processing like applying global filters can be done here
      end
    end
  end
end
