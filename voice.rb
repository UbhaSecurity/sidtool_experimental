module Sidtool
  class Voice
    attr_accessor :frequency, :pulse_width, :control_register
    attr_accessor :attack, :decay, :sustain, :release

    def initialize(sid6581, voice_number)
      @sid6581 = sid6581
      @voice_number = voice_number
      @frequency = 0
      @pulse_width = 0
      @control_register = 0
      @attack = 0
      @decay = 0
      @sustain = 0
      @release = 0
      @amplitude = 0.0
      @phase = 0.0
    end

    def set_frequency(low_byte, high_byte)
      @frequency = (high_byte << 8) | low_byte
      # Update SID register accordingly
      @sid6581.write_register(Sid6581::FREQ_LO[@voice_number], low_byte)
      @sid6581.write_register(Sid6581::FREQ_HI[@voice_number], high_byte)
    end

    def set_pulse_width(low_byte, high_byte)
      @pulse_width = (high_byte << 8) | low_byte
      # Update SID register accordingly
      @sid6581.write_register(Sid6581::PW_LO[@voice_number], low_byte)
      @sid6581.write_register(Sid6581::PW_HI[@voice_number], high_byte)
    end

    def set_control_register(value)
      @control_register = value
      # Update SID register accordingly
      @sid6581.write_register(Sid6581::CR[@voice_number], value)
    end

    def set_adsr(attack_decay, sustain_release)
      @attack, @decay = decode_adsr(attack_decay)
      @sustain, @release = decode_adsr(sustain_release)
      # Update SID register accordingly
      @sid6581.write_register(Sid6581::AD[@voice_number], attack_decay)
      @sid6581.write_register(Sid6581::SR[@voice_number], sustain_release)
    end

    def generate_waveform
      # Generate waveform based on control_register settings and current phase
      # ...
    end

    def process_adsr
      # Process ADSR envelope based on current state and ADSR settings
      # ...
    end

    private

    def decode_adsr(value)
      attack = value >> 4
      decay = value & 0x0F
      [attack, decay]
    end
  end
end
