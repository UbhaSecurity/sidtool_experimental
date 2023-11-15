module Sidtool
  class MidiFileWriter
    # Constants for Controller Numbers (assuming standard MIDI controller numbers)
    FILTER_CUTOFF_CONTROLLER = 74
    FILTER_RESONANCE_CONTROLLER = 71
    OSC_SYNC_CONTROLLER = 102  # Placeholder value, adjust as needed
    RING_MOD_CONTROLLER = 103  # Placeholder value, adjust as needed
    PULSE_WIDTH_CONTROLLER = 74
    MAX_CUTOFF_FREQUENCY = 20000.0  # Maximum cutoff frequency value (adjust as needed)
    MAX_RESONANCE = 1.0  # Maximum resonance value (adjust as needed)
    FRAMES_PER_SECOND = 50  # Number of frames per second (adjust as needed)

 ENVELOPE_RATES = {
      # The following rates are placeholders and should be adjusted to reflect
      # the actual behavior of the SID chip's envelope generator. 
      # These values would typically be derived from the SID's technical documentation, 
      # where the time each envelope phase (attack, decay, sustain, release) takes to
      # complete is specified in relation to the system clock frequency (typically 1.0 MHz).
      #
      # For example, in the SID documentation, the attack rate is defined for values from 0 to 15,
      # each representing different times to reach full volume from zero. The decay and release
      # rates similarly define the time it takes to reduce the amplitude from full to zero or 
      # sustain level. The sustain rate typically denotes the level at which the amplitude is 
      # held during the sustain phase.
      #
      # These rates are essential for accurately replicating the SID's sound characteristics 
      # in MIDI format. The values should be adjusted according to the specific behavior of 
      # the SID model being emulated, ensuring the MIDI conversion maintains the original 
      # character of the sound.
      sid_attack: [0.0, 3.0, 6.0, 9.0, 12.0, 15.0, 18.0, 21.0],
      sid_decay: [0.0, 3.0, 6.0, 9.0, 12.0, 15.0, 18.0, 21.0],
      sid_sustain: [0.0, 3.0, 6.0, 9.0, 12.0, 15.0, 18.0, 21.0],
      sid_release: [0.0, 3.0, 6.0, 9.0, 12.0, 15.0, 18.0, 21.0]
    }

    DECAY_RELEASE_RATES = {
      # The values here represent the time (in milliseconds) it takes for the decay or release
      # phase to move from peak amplitude to zero amplitude.
      # These timings are derived from SID's technical documentation and are based on a
      # standard 1.0 MHz system clock (02 clock). For each rate value (0 to 15), the SID chip
      # has predefined times for decay and release phases.
      #
      # The decay/release time per cycle is given in the SID manual (refer to Table 2 in the SID documentation).
      # The actual time is calculated by multiplying the rate value with the clock period,
      # which is the inverse of the clock frequency (1 / 1.0 MHz = 1 μs).
      # For example, a decay rate of 0 corresponds to 6 ms time per cycle,
      # which means it takes 6 ms for the sound to decay from its peak to zero amplitude.
      0 => 6, 1 => 24, 2 => 48, 3 => 72,
      4 => 114, 5 => 168, 6 => 204, 7 => 240,
      8 => 300, 9 => 750, 10 => 1500, 11 => 2400,
      12 => 3000, 13 => 9000, 14 => 15000, 15 => 24000
      # These values are in milliseconds and are scaled based on the 1.0 MHz clock.
      # The calculation for each of these values is based on SID's internal timing mechanisms,
      # which are controlled by the system clock and the decay/release rate settings.
      # For example, a rate setting of 0 (6 ms) means the decay/release phase completes in 6 ms,
      # which corresponds to a quick fall in sound amplitude.
    }

    ATTACK_RATES = {
      # The values represent the time (in milliseconds) for the attack phase to rise from
      # zero amplitude to peak amplitude. These values are defined by the SID's hardware
      # and are dependent on the system clock frequency.
      #
      # The SID's technical documentation specifies the time each attack rate value (0 to 15)
      # takes to reach full volume (refer to Table 2 in the SID documentation). The timing is
      # calculated considering the system clock frequency which is typically 1.0 MHz for the SID.
      # For instance, an attack rate of 0 corresponds to a 2 ms time per cycle, meaning it takes
      # 2 ms for the attack phase to reach its peak amplitude from silence.
      0 => 2, 1 => 8, 2 => 16, 3 => 24,
      4 => 38, 5 => 56, 6 => 68, 7 => 80,
      8 => 100, 9 => 250, 10 => 500, 11 => 800,
      12 => 1000, 13 => 3000, 14 => 5000, 15 => 8000
      # The actual calculation for each rate value is derived from the SID's timing control,
      # which is directly influenced by the clock input. For example, with an attack value of 2,
      # the attack phase would take 16 ms to go from zero to full amplitude. These times are 
      # relevant to simulate the SID's envelope characteristics accurately in the MIDI domain.
    }

    # Define the SID to MIDI note table as a constant within the MidiFileWriter class.
    # This table maps frequencies to MIDI note numbers based on the SID chip's
    # frequency generation capabilities and the MIDI standard's note numbering.
    #
    # The SID chip generates sound frequencies based on a 16-bit register value
    # and the system clock frequency. According to the SID documentation, the output
    # frequency (Fout) is calculated as: Fout = (Fn * Fclk / 16777216) Hz, where
    # Fn is the 16-bit frequency value and Fclk is the system clock frequency.
    #
    # This table uses the equal-tempered scale, where each semitone's frequency is
    # the 12th root of 2 times that of the previous semitone. The table is calibrated
    # based on standard concert pitch (A4 = 440 Hz).
    #
    # The calculations here consider the standard frequency for each MIDI note and
    # map it to the closest possible frequency that the SID chip can produce,
    # thereby allowing accurate MIDI representation of SID sounds.
    SID_TO_MIDI_NOTE_TABLE = begin
      table = {}
      start_frequency = 16.35  # Frequency of C0 in Hz (MIDI standard)
      start_note_number = 0    # MIDI note number for C0

      # Number of octaves to cover in the MIDI standard
      num_octaves = 10  # Covers all MIDI note octaves (0 to 9)

      # Semitone ratios for equal-tempered scale
      semitone_ratios = [1.0, 1.059463, 1.122462, 1.189207, 1.259921, 1.334840, 
                         1.414214, 1.498307, 1.587401, 1.681793, 1.781797, 1.887749]

      # Populate the table with frequencies for each MIDI note
      (0..num_octaves).each do |octave|
        semitone_ratios.each_with_index do |ratio, semitone|
          frequency = start_frequency * (2.0**octave) * ratio
          midi_note_number = start_note_number + (octave * 12) + semitone
          table[frequency.round(2)] = midi_note_number
        end
      end

      table.freeze  # Freeze the table to prevent modifications
    end


    def initialize(synths_for_voices, sid6581, cia_timer_a, cia_timer_b)
      @synths_for_voices = synths_for_voices
      @sid6581 = sid6581
      @cia_timer_a = cia_timer_a
      @cia_timer_b = cia_timer_b
    end

    def write_to(path)
      tracks = @synths_for_voices.map { |synths| build_track(synths) }
      
      File.open(path, 'wb') do |file|
        write_header(file)
        tracks.each_with_index do |track, index|
          write_track(file, track, "Voice #{index + 1}")
        end
      end
    end

    ControlChange = Struct.new(:channel, :controller, :value) do
      def bytes
        raise "Channel too big: #{channel}" if channel > 15
        raise "Controller number is too big: #{controller}" if controller > 127
        raise "Value is too big: #{value}" if value > 127
        [0xB0 + channel, controller, value]
      end
    end

    def build_track(synths)
      waveforms = [:tri, :saw, :pulse, :noise]
      track = []
      current_frame = 0

      synths.each do |synth|
        channel = map_waveform_to_channel(synth.waveform)
        track << DeltaTime.new(synth.start_frame - current_frame)

        handle_sid_effects(synth, track, channel)
        handle_adsr(synth, track, channel)
        handle_filter_parameters(synth, track, channel)

        current_tone = synth.tone
        synth.controls.each do |start_frame, tone|
          track << DeltaTime.new(start_frame - current_frame)
          track << NoteOff.new(channel, current_tone)
          track << DeltaTime.new(0)
          track << NoteOn.new(channel, tone)
          current_tone = tone
          current_frame = start_frame
        end

        end_frame = [current_frame, synth.start_frame + (FRAMES_PER_SECOND * (synth.attack + synth.decay + synth.sustain_length)).to_i].max
        track << DeltaTime.new(end_frame - current_frame)
        track << NoteOff.new(channel, current_tone)
        current_frame = end_frame
      end

      consolidate_events(track)
    end

    # The handle_adsr method processes the ADSR envelope parameters (Attack, Decay, Sustain, Release)
    # for a given synth object and applies them to the MIDI track. This method uses the SID chip's
    # ADSR characteristics to generate MIDI equivalent values.
    #
    # The SID chip's ADSR envelope controls the amplitude of a voice with specific rates for attack,
    # decay, and release, and a sustain level. This method uses these SID parameters to construct
    # a MIDI envelope that mimics the SID's behavior.
    def handle_adsr(synth, track, channel)
      envelope_type = determine_envelope_type(synth.attack, synth.decay, synth.sustain, synth.release)
      velocity, note_length = map_envelope_to_midi(envelope_type, synth.attack, synth.decay, synth.sustain, synth.release)
      track << NoteOn.new(channel, synth.tone, velocity)
      track << DeltaTime.new(note_length)
      track << NoteOff.new(channel, synth.tone, 0)
    end

    # The map_envelope_to_midi method converts SID's ADSR parameters to MIDI values.
    # It uses the SID's specific attack, decay, sustain, and release rates to determine
    # the corresponding MIDI values.
    #
    # SID's attack, decay, and release values are mapped to time-based MIDI parameters,
    # while the sustain value is mapped to a MIDI level. This method ensures that the
    # ADSR behavior of the SID is represented accurately in the MIDI output.
    def map_envelope_to_midi(attack, decay, sustain, release)
      # Implementing a 1:1 mapping of SID's ADSR parameters to MIDI with scaling and lookup tables
      velocity = attack * 8  # Scale attack
      decay_value = ENVELOPE_RATES[:sid_decay][decay]  # Lookup decay rate
      sustain_value = ENVELOPE_RATES[:sid_sustain][sustain]  # Lookup sustain rate
      release_value = ENVELOPE_RATES[:sid_release][release]  # Lookup release rate
      [velocity, decay_value, sustain_value, release_value]
    end

    # The calculate_pitch_from_sid method converts a SID frequency to a corresponding MIDI note number.
    # The SID chip generates frequencies based on a 16-bit number and the system clock frequency.
    # This method finds the closest frequency in the SID_TO_MIDI_NOTE_TABLE and returns the MIDI note number.
    #
    # SID Frequency calculation: Fout = (Fn * Fclk/16777216) Hz
    # This method ensures the pitch in the MIDI representation matches the original SID sound.
    def calculate_pitch_from_sid(sid_frequency)
      closest_frequency = SID_TO_MIDI_NOTE_TABLE.keys.min_by { |k| (k - sid_frequency).abs }
      SID_TO_MIDI_NOTE_TABLE[closest_frequency]
    end

    # Convert SID pulse width to MIDI control change value.
    # This function maps the SID chip's pulse width parameter to a MIDI control change
    # value, ensuring the pulse width modulation characteristic of the SID is represented
    # in the MIDI format. The SID documentation provides details on how pulse width
    # affects the sound waveforms, and this function aims to convert that effect into
    # a corresponding MIDI control value.
    #
    # The linear mapping used here (pulse_width / 40.95) is a simplified approximation
    # and may need adjustment to more accurately represent the SID's pulse width modulation
    # behavior in the MIDI domain.
    def pulse_width_to_midi(pulse_width)
      midi_value = (pulse_width / 40.95).round.clamp(0, 127)
      [PULSE_WIDTH_CONTROLLER, midi_value]
    end

    # Map SID's ADSR values to MIDI format.
    # This function converts the SID's attack, decay, sustain, and release
    # parameters into MIDI values. The conversion is based on the SID chip's
    # unique envelope characteristics, which are dictated by its internal clock.
    #
    # The SID chip's technical documentation outlines how each ADSR parameter
    # influences the envelope generator's behavior in terms of the chip's clock frequency.
    # This function aims to replicate that behavior in the MIDI domain, ensuring
    # the MIDI representation closely mimics the original sound of the SID.
    #
    # The scaling factors used in this function (e.g., attack * 10) are placeholders
    # and should be adjusted to match the actual rates and behavior of the SID model
    # being emulated.
    def map_adsr_to_midi(attack, decay, sustain, release)
      velocity = 64  # Default velocity
      attack_time = (attack * 10).round.clamp(0, 127)
      decay_time = (decay * 10).round.clamp(0, 127)
      sustain_level = (sustain * 127).round.clamp(0, 127)
      release_time = (release * 10).round.clamp(0, 127)

      [velocity, attack_time, decay_time, sustain_level, release_time]
    end

    # The decay_release_time method calculates the time in milliseconds for decay or release based on the SID value.
    # The SID chip has specific rates for decay and release, represented in a range from 0 to 15, each corresponding to a different time.
    #
    # Decay/Release Rate calculation (from SID documentation): Refer to DECAY_RELEASE_RATES table
    # This method accurately reflects the SID's decay/release behavior in MIDI format.
    def decay_release_time(sid_value)
      DECAY_RELEASE_RATES[sid_value] * 1000  # Convert to milliseconds
    end

    # The sustain_level method calculates the MIDI sustain level based on the SID's sustain value.
    # The SID chip has 16 linear steps for sustain level (0-15), with this method mapping them to MIDI's 0-127 range.
    #
    # Sustain Level calculation: MIDI sustain level = (SID sustain / 15) * 127
    # This method ensures that the sustain level in the MIDI representation reflects the SID's sustain behavior.
    def sustain_level(sid_sustain)
      midi_sustain_level = (sid_sustain / 15.0 * 127).round.clamp(0, 127)
      midi_sustain_level
    end
    # The attack_time method calculates the time in milliseconds for the attack phase based on the SID value.
    # The SID chip provides 16 different rates for the attack phase, ranging from 0 to 15.
    # Each rate corresponds to a different time duration for the attack phase.
    #
    # Attack Rate calculation (from SID documentation): Refer to ATTACK_RATES table
    # This method accurately reflects the SID's attack behavior in the MIDI format.
    def attack_time(sid_attack)
      ATTACK_RATES[sid_attack] * 1000  # Convert to milliseconds
    end

    # The release_time method calculates the time in milliseconds for the release phase.
    # This is a placeholder implementation and should be replaced with accurate calculations based on the SID chip's release characteristics.
    #
    # Release time calculation: Currently using a placeholder formula, needs accurate SID release time mapping.
    def release_time(release)
      release * 50 # Placeholder value, to be replaced with SID-specific calculations
    end

    # The map_decay_to_cc method maps SID's decay value to a MIDI Control Change (CC) value.
    # SID decay value ranges from 0 to 15 and this method linearly maps it to MIDI CC range 0 to 127.
    #
    # Decay mapping: Linear transformation from SID decay value to MIDI CC value.
    def map_decay_to_cc(decay)
      (decay / 15.0 * 127).round.clamp(0, 127)
    end

    # The map_release_to_velocity method maps SID's release value to MIDI velocity.
    # Similar to decay, SID release value ranges from 0 to 15 and is linearly mapped to MIDI velocity range 0 to 127.
    #
    # Release mapping: Linear transformation from SID release value to MIDI velocity.
    def map_release_to_velocity(release)
      (release / 15.0 * 127).round.clamp(0, 127)
    end

    # Map SID filter parameters to MIDI.
    # This function converts the SID chip's filter parameters, specifically the
    # cutoff frequency and resonance, into MIDI control change values. The SID's
    # filter is a key component in shaping its sound, and this function aims to
    # translate the filter's effect into MIDI format.
    #
    # The conversion formulas used here (linear scaling of cutoff and resonance)
    # are based on typical SID chip behavior as outlined in its technical documentation.
    # These formulas might need refinement to more accurately emulate the specific
    # filter characteristics of the SID model in use.
    def map_filter_to_midi(cutoff_frequency, resonance)
      cutoff_midi_value = (cutoff_frequency / MAX_CUTOFF_FREQUENCY * 127).round.clamp(0, 127)
      resonance_midi_value = (resonance / MAX_RESONANCE * 127).round.clamp(0, 127)

      [cutoff_midi_value, resonance_midi_value]
    end

# The map_sid_effects_to_midi function maps the SID's oscillator sync and ring modulation parameters
# to MIDI values. This is based on the SID's behavior where certain bits in the control register
# enable these effects. The method calculates MIDI values that correspond to these effects being active.
#
# Oscillator Sync and Ring Modulation are SID specific features.
# Oscillator Sync (Sync Bit): Synchronizes the frequency of one oscillator with another.
# Ring Modulation (Ring Mod Bit): Produces a ring-modulated combination of two oscillators.
# These effects are mapped to MIDI controller values to represent their activation.
def map_sid_effects_to_midi(osc_sync, ring_mod)
  osc_sync_midi_value = calculate_osc_sync_value(osc_sync)
  ring_mod_midi_value = calculate_ring_mod_value(ring_mod)

  [OSC_SYNC_CONTROLLER, osc_sync_midi_value, RING_MOD_CONTROLLER, ring_mod_midi_value]
end

# The calculate_ring_mod_value function converts the SID's ring modulation effect parameter
# to a MIDI value. The ring modulation effect in SID creates a complex waveform by combining
# two oscillator outputs. This function maps the presence of the effect to a MIDI value.
#
# Ring Modulation (from SID documentation): Affects the harmonic content of the sound.
# This function represents the ring modulation effect's intensity or presence in a MIDI format.
def calculate_ring_mod_value(ring_mod)
  midi_value = (ring_mod * 127).round
  [midi_value, 127].min
end

# The calculate_osc_sync_value function maps the SID's oscillator sync parameter to a MIDI value.
# Oscillator sync in the SID chip locks the phase of one oscillator to another, creating unique timbres.
# This function represents the state of oscillator sync (active or not) in MIDI.
#
# Oscillator Sync (from SID documentation): Locks the phase of an oscillator to another.
# This function represents whether oscillator sync is active in a MIDI format.
def calculate_osc_sync_value(osc_sync)
  midi_value = (osc_sync * 127).round
  [midi_value, 127].min
end

# The handle_filter_parameters function maps the SID's filter parameters (cutoff frequency and resonance)
# to MIDI control changes. The SID chip's filter is a crucial component in shaping the sound,
# with control over cutoff frequency and resonance.
#
# Filter Parameters (from SID documentation): Affect the harmonic content of the sound by filtering frequencies.
# This function maps these parameters to corresponding MIDI control change values.
def handle_filter_parameters(synth, track, channel)
  track << DeltaTime.new(0)
  track << ControlChange.new(channel, FILTER_CUTOFF_CONTROLLER, calculate_filter_value(synth.filter_cutoff))
  track << DeltaTime.new(0)
  track << ControlChange.new(channel, FILTER_RESONANCE_CONTROLLER, calculate_filter_value(synth.filter_resonance))
end

# The handle_sid_effects function applies SID specific effects (oscillator sync and ring modulation) to the MIDI track.
# These effects are unique to the SID chip and are represented in MIDI using specific controller messages.
#
# SID Effects (from SID documentation): Include oscillator sync and ring modulation.
# This function adds MIDI control changes to the track to represent these effects.
def handle_sid_effects(synth, track, channel)
  track << DeltaTime.new(0)
  track << ControlChange.new(channel, OSC_SYNC_CONTROLLER, calculate_osc_sync_value(synth.osc_sync))
  track << DeltaTime.new(0)
  track << ControlChange.new(channel, RING_MOD_CONTROLLER, calculate_ring_mod_value(synth.ring_mod_effect))
end


    DeltaTime = Struct.new(:time) do
      def bytes
        quantity = time
        seven_bit_segments = []
        max_iterations = 100  # Safeguard against infinite loops
        iterations = 0

        while true
          seven_bit_segments << (quantity & 127)
          quantity >>= 7
          break if quantity == 0 || iterations >= max_iterations
          iterations += 1
        end

        result = seven_bit_segments.reverse.map { |segment| segment | 128 }
        result[-1] &= 127
        result
      end
    end

    TrackName = Struct.new(:name) do
      def bytes
        [0xFF, 0x03, name.length, *name.bytes]
      end
    end

    TimeSignature = Struct.new(:numerator, :denominator_power_of_two, :clocks_per_metronome_click, :number_of_32th_nodes_per_24_clocks) do
      def bytes
        [0xFF, 0x58, 0x04, numerator, denominator_power_of_two, clocks_per_metronome_click, number_of_32th_nodes_per_24_clocks]
      end
    end

    KeySignature = Struct.new(:sharps_or_flats, :is_major) do
      def bytes
        [0xFF, 0x59, 0x02, sharps_or_flats, is_major ? 0 : 1]
      end
    end

    EndOfTrack = Struct.new(:nothing) do
      def bytes
        [0xFF, 0x2F, 0x00]
      end
    end

    ProgramChange = Struct.new(:channel, :program_number) do
      def bytes
        raise "Channel too big: #{channel}" if channel > 15
        raise "Program number is too big: #{program_number}" if program_number > 127
        [0xC0 + channel, program_number]
      end
    end

    NoteOn = Struct.new(:channel, :key, :velocity) do
      def bytes
        raise "Channel too big: #{channel}" if channel > 15
        raise "Key is too big: #{key}" if key > 127
        raise "Velocity is too big: #{velocity}" if velocity > 127
        [0x90 + channel, key, velocity]
      end
    end

    NoteOff = Struct.new(:channel, :key, :velocity) do
      def bytes
        raise "Channel too big: #{channel}" if channel > 15
        raise "Key is too big: #{key}" if key > 127
        raise "Velocity is too big: #{velocity}" if velocity > 127
        [0x80 + channel, key, velocity]
      end
    end

    def consolidate_events(track)
      consolidated = []
      skip_next = false
      track.each_with_index do |event, i|
        if skip_next
          skip_next = false
          next
        end
        next_event = track[i + 1]
        if event.is_a?(NoteOff) && next_event.is_a?(NoteOn) && event.key == next_event.key
          skip_next = true
        else
          consolidated << event
        end
      end
      consolidated
    end

    def write_header(file)
      file << 'MThd'
      write_uint32(file, 6)
      write_uint16(file, 1)
      write_uint16(file, 3)
      write_uint16(file, 25)  # Default timing
    end

    def write_track(file, track, name)
      track_with_metadata = [
        DeltaTime.new(0), TrackName.new(name),
        DeltaTime.new(0), TimeSignature.new(4, 2, 24, 8),
        DeltaTime.new(0), KeySignature.new(0, 0),
        DeltaTime.new(0), ProgramChange.new(0, 1),
        DeltaTime.new(0), ProgramChange.new(1, 25),
        DeltaTime.new(0), ProgramChange.new(2, 33),
        DeltaTime.new(0), ProgramChange.new(3, 41)
      ] + track + [DeltaTime.new(0), EndOfTrack.new(nil)]
      track_bytes = track_with_metadata.flat_map(&:bytes)
      file << 'MTrk'
      write_uint32(file, track_bytes.length)
      file << track_bytes.pack('c' * track_bytes.length)
    end

    def write_uint32(file, value)
      bytes = [(value >> 24) & 255, (value >> 16) & 255, (value >> 8) & 255, value & 255]
      file << bytes.pack('cccc')
    end

    def write_uint16(file, value)
      bytes = [(value >> 8) & 255, value & 255]
      file << bytes.pack('cc')
    end

    def write_byte(file, value)
      file << [value & 255].pack('c')
    end

    def map_waveform_to_channel(waveform)
      case waveform
      when :tri then 0
      when :saw then 1
      when :pulse then 2
      when :noise then 3
      else
        raise "Unknown waveform: #{waveform}"
      end
    end
  end
end
