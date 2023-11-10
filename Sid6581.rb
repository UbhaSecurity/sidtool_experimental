module Sidtool
class Sid6581
  # Registers for each voice
  FREQ_LO = [0xD400, 0xD407, 0xD40E]
  FREQ_HI = [0xD401, 0xD408, 0xD40F]
  PW_LO   = [0xD402, 0xD409, 0xD410]
  PW_HI   = [0xD403, 0xD40A, 0xD411]
  CR      = [0xD404, 0xD40B, 0xD412]
  AD      = [0xD405, 0xD40C, 0xD413]
  SR      = [0xD406, 0xD40D, 0xD414]

  # Global registers
  FC_LO      = 0xD415
  FC_HI      = 0xD416
  RES_FILT   = 0xD417
  MODE_VOL   = 0xD418
  POTX       = 0xD419
  POTY       = 0xD41A
  OSC3       = 0xD41B
  ENV3       = 0xD41C

  def initialize
    # Initialize voices and global settings
    @voices = Array.new(3) { Voice.new }
    # ... other initializations
  end

  def write_register(address, value)
    case address
    when *FREQ_LO
      voice_index = FREQ_LO.index(address)
      @voices[voice_index].frequency = (@voices[voice_index].frequency & 0xFF00) | value
    when *FREQ_HI
      voice_index = FREQ_HI.index(address)
      @voices[voice_index].frequency = (@voices[voice_index].frequency & 0x00FF) | (value << 8)
    when *PW_LO
      voice_index = PW_LO.index(address)
      @voices[voice_index].pulse_width = (@voices[voice_index].pulse_width & 0x0F00) | value
    when *PW_HI
      voice_index = PW_HI.index(address)
      @voices[voice_index].pulse_width = (@voices[voice_index].pulse_width & 0x00FF) | ((value & 0x0F) << 8)
    when *CR
      voice_index = CR.index(address)
      @voices[voice_index].control_register = value
    when *AD
      voice_index = AD.index(address)
      @voices[voice_index].attack = value >> 4
      @voices[voice_index].decay = value & 0x0F
    when *SR
      voice_index = SR.index(address)
      @voices[voice_index].sustain = value >> 4
      @voices[voice_index].release = value & 0x0F
    # Add handling for global registers
    # ...
    end
  end

  # Implement read_register if needed
  # ...

  # Additional methods for SID functionality
  # ...
end

class Voice
  attr_accessor :frequency, :pulse_width, :control_register, :attack, :decay, :sustain, :release

  def initialize
    @frequency = 0
    @pulse_width = 0
    @control_register = 0
    @attack = 0
    @decay = 0
    @sustain = 0
    @release = 0
  end
 def generate_waveform
    case control_register & 0b1111 # Assuming the last 4 bits determine the waveform
    when 0b0001
      generate_triangle_wave
    when 0b0010
      generate_sawtooth_wave
    # Add other waveforms...
    else
      0 # Silence if no waveform is selected
    end
  end

  private

def generate_triangle_wave(frequency, sample_rate)
  increment = frequency * 2 / sample_rate
  value = 0
  direction = 1

  generate_sample do
    value += increment * direction
    direction *= -1 if value >= 1 || value <= -1
    value
  end
end

def generate_sawtooth_wave(frequency, sample_rate)
  increment = frequency / sample_rate
  value = -1

  generate_sample do
    value += increment
    value = -1 if value >= 1
    value
  end
end

def generate_pulse_wave(frequency, sample_rate, pulse_width)
  increment = frequency / sample_rate
  phase = 0
  threshold = pulse_width / 4096.0 # Normalize 12-bit pulse width

  generate_sample do
    phase = (phase + increment) % 1
    phase < threshold ? 1 : -1
  end
end

def generate_noise_wave(sample_rate)
  lfsr = 0xACE1 # Any non-zero start state
  generate_sample do
    bit = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5)) & 1
    lfsr = (lfsr >> 1) | (bit << 15)
    lfsr & 1 == 1 ? 0.5 : -0.5
  end
end

def process_adsr(voice, sample_rate)
  case voice.adsr_phase
  when :attack
    # Increment amplitude linearly until peak
    voice.amplitude += (1.0 / (voice.attack * sample_rate))
    voice.adsr_phase = :decay if voice.amplitude >= 1
  when :decay
    # Decrement amplitude until sustain level
    target = voice.sustain / 15.0
    voice.amplitude -= (1.0 / (voice.decay * sample_rate))
    voice.adsr_phase = :sustain if voice.amplitude <= target
  when :sustain
    # Maintain amplitude at sustain level
    voice.amplitude = voice.sustain / 15.0
  when :release
    # Decrement amplitude until silent
    voice.amplitude -= (1.0 / (voice.release * sample_rate))
    voice.adsr_phase = :off if voice.amplitude <= 0
  end
end


end
end

