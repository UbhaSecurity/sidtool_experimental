module Sidtool
  class Synth
    attr_accessor :waveform, :frequency, :pulse_width
    attr_accessor :attack, :decay, :sustain, :release
    attr_reader :voice_number

    def initialize(sid6581, voice_number)
      @sid6581 = sid6581
      @voice_number = voice_number
      @waveform = :triangle
      @frequency = 0
      @pulse_width = 0
      @attack = 0
      @decay = 0
      @sustain = 0
      @release = 0
      @gate_bit = false
    end

    def update_parameters
      # Set waveform, frequency, pulse width, ADSR in SID registers
      control_register_value = calculate_waveform_bits
      control_register_value |= 1 if @gate_bit  # Set gate bit if it's on
      @sid6581.set_control_register(@voice_number, control_register_value)
      @sid6581.set_frequency(@voice_number, frequency_to_bytes(@frequency))
      @sid6581.set_pulse_width(@voice_number, pulse_width_to_bytes(@pulse_width))
      @sid6581.set_adsr(@voice_number, attack_decay_to_byte, sustain_release_to_byte)
    end

    def start_note
      @gate_bit = true
      update_parameters
    end

    def stop_note
      @gate_bit = false
      update_parameters
    end

    private

    def frequency_to_bytes(frequency)
      # Convert frequency to two bytes for SID
      # ...
    end

    def pulse_width_to_bytes(pulse_width)
      # Convert pulse width to two bytes for SID
      # ...
    end

    def attack_decay_to_byte
      (@attack << 4) | @decay
    end

    def sustain_release_to_byte
      (@sustain << 4) | @release
    end

    def calculate_waveform_bits
      # Calculate waveform bits based on selected waveform
      case @waveform
      when :triangle
        Sid6581::WAVEFORM_TRIANGLE
      when :sawtooth
        Sid6581::WAVEFORM_SAWTOOTH
      when :pulse
        Sid6581::WAVEFORM_PULSE
      when :noise
        Sid6581::WAVEFORM_NOISE
      else
        0 # Silence if no waveform is selected
      end
    end
  end
end
