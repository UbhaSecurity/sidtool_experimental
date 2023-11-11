module Sidtool
  class Sid6581
    WAVEFORM_TRIANGLE = 0x01
    WAVEFORM_SAWTOOTH = 0x02
    WAVEFORM_PULSE = 0x04
    WAVEFORM_NOISE = 0x08

    FREQ_LO = [0xD400, 0xD407, 0xD40E]
    FREQ_HI = [0xD401, 0xD408, 0xD40F]
    PW_LO   = [0xD402, 0xD409, 0xD410]
    PW_HI   = [0xD403, 0xD40A, 0xD411]
    CR      = [0xD404, 0xD40B, 0xD412]
    AD      = [0xD405, 0xD40C, 0xD413]
    SR      = [0xD406, 0xD40D, 0xD414]

    FC_LO      = 0xD415
    FC_HI      = 0xD416
    RES_FILT   = 0xD417
    MODE_VOL   = 0xD418
    POTX       = 0xD419
    POTY       = 0xD41A
    OSC3       = 0xD41B
    ENV3       = 0xD41C

    def initialize
      @voices = Array.new(3) { |voice_number| Voice.new(self, voice_number) }
      @global_filter_cutoff = 0
      @global_filter_resonance = 0
      @global_volume = 0
    end

    def write_register(address, value)
      case address
      when *FREQ_LO
        voice_index = FREQ_LO.index(address)
        @voices[voice_index].frequency_low = value
      when *FREQ_HI
        voice_index = FREQ_HI.index(address)
        @voices[voice_index].frequency_high = value
      when *PW_LO
        voice_index = PW_LO.index(address)
        @voices[voice_index].pulse_low = value
      when *PW_HI
        voice_index = PW_HI.index(address)
        @voices[voice_index].pulse_high = value
      when *CR
        voice_index = CR.index(address)
        @voices[voice_index].control_register = value
      when *AD
        voice_index = AD.index(address)
        @voices[voice_index].attack_decay = value
      when *SR
        voice_index = SR.index(address)
        @voices[voice_index].sustain_release = value
      # Handle global registers
      # ...
      end
    end

    def read_register(address)
      # Implement reading from the SID registers
      # ...
    end

    def generate_sound
      # Iterate over each voice to generate sound
      @voices.each do |voice|
        voice.finish_frame
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

  private

  def calculate_phase(voice, sample_rate)
    voice.phase = (voice.phase + (voice.frequency.to_f / sample_rate)) % 1.0
    voice.phase
  end
end
