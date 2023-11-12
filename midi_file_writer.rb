module Sidtool
  class MidiFileWriter
    # Constants for Controller Numbers (assuming standard MIDI controller numbers)
    FILTER_CUTOFF_CONTROLLER = 74
    FILTER_RESONANCE_CONTROLLER = 71
    OSC_SYNC_CONTROLLER = 102  # Placeholder value, adjust as needed
    RING_MOD_CONTROLLER = 103  # Placeholder value, adjust as needed

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

    private

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

def handle_adsr(synth, track, channel)
  envelope_type = determine_envelope_type(synth.attack, synth.decay, synth.sustain, synth.release)
  velocity, note_length = map_envelope_to_midi(envelope_type, synth.attack, synth.decay, synth.sustain, synth.release)
  track << NoteOn.new(channel, synth.tone, velocity)
  track << DeltaTime.new(note_length)
  track << NoteOff.new(channel, synth.tone, 0)
end

def determine_envelope_type(attack, decay, sustain, release)
  # Example logic - this should be refined based on the specific characteristics of the SID chip
  if attack < 2 && decay > 8 && sustain == 0
    :percussion
  elsif attack < 2 && sustain > 0
    :piano
  else
    :generic
  end
end

def handle_waveform_parameters(synth, track, channel)
  case synth.waveform
  when :pulse
    pulse_width_value = pulse_width_to_midi(synth.pulse_width)
    track << ControlChange.new(channel, PULSE_WIDTH_CONTROLLER, pulse_width_value)
  when :noise
    # Noise might be simulated using a combination of MIDI messages
    # For instance, using a specific instrument or modulation
  end
end

def map_envelope_to_midi(attack, decay, sustain, release)
  # Implementing logic based on SID's ADSR characteristics and mapping them to MIDI
  # This is a simplified example; it can be further refined based on experimentation
  velocity = [attack * 8, 127].min # Simplified mapping, can be adjusted
  note_length = sustain_to_length(sustain) + decay_to_length(decay) + release_to_length(release)
  [velocity, note_length]
end

def calculate_pitch_from_sid(sid_frequency)
  # Convert SID frequency to MIDI note number
  # Assuming A4 = 440Hz is MIDI note number 69
  midi_note = 69 + 12 * Math.log2(sid_frequency.to_f / 440)
  midi_note.round
end

def pulse_width_to_midi(pulse_width)
  # Convert SID pulse width to MIDI control change value
  # Assuming linear mapping; can be adjusted for accuracy
  midi_value = (pulse_width / 4095.0 * 127).round
  [midi_value, 127].min
end

def sustain_to_length(sustain)
  # More precise mapping considering SID's characteristics
  sustain_length = (sustain / 15.0) * max_sustain_length # Define max_sustain_length based on SID's behavior
  sustain_length.round
end

def decay_to_length(decay)
  # Similar approach as sustain_to_length
  decay_length = (decay / 15.0) * max_decay_length # Define max_decay_length based on SID's behavior
  decay_length.round
end

def release_to_length(release)
  # Similar approach as sustain_to_length and decay_to_length
  release_length = (release / 15.0) * max_release_length # Define max_release_length based on SID's behavior
  release_length.round
end

    def handle_filter_parameters(synth, track, channel)
      track << DeltaTime.new(0)
      track << ControlChange.new(channel, FILTER_CUTOFF_CONTROLLER, calculate_filter_value(synth.filter_cutoff))
      track << DeltaTime.new(0)
      track << ControlChange.new(channel, FILTER_RESONANCE_CONTROLLER, calculate_filter_value(synth.filter_resonance))
    end

    def calculate_filter_value(filter_param)
      # Map SID filter parameter to MIDI range (0-127)
      [filter_param, 127].min
    end

    def handle_sid_effects(synth, track, channel)
      track << DeltaTime.new(0)
      track << ControlChange.new(channel, OSC_SYNC_CONTROLLER, calculate_osc_sync_value(synth.osc_sync))
      track << DeltaTime.new(0)
      track << ControlChange.new(channel, RING_MOD_CONTROLLER, calculate_ring_mod_value(synth.ring_mod_effect))
    end

def handle_oscillator_sync(synth, track, channel)
  # Translate oscillator sync effects into MIDI
  # This could be done using MIDI control changes
  # Example: Use a control change to alter pitch/timbre
  osc_sync_value = calculate_osc_sync_value(synth.osc_sync)
  track << ControlChange.new(channel, OSC_SYNC_MIDI_CONTROLLER, osc_sync_value)
end

def handle_ring_modulation(synth, track, channel)
  # Translate ring modulation effects into MIDI
  # This could involve selecting a specific MIDI instrument or using control changes
  ring_mod_value = calculate_ring_mod_value(synth.ring_mod_effect)
  track << ControlChange.new(channel, RING_MOD_MIDI_CONTROLLER, ring_mod_value)
end

    def calculate_osc_sync_value(osc_sync)
    # Map SID osc_sync to a MIDI control value (0-127)
    [osc_sync, 127].min
    end

    def calculate_ring_mod_value(ring_mod)
      # Map SID ring_mod_effect to a MIDI control value (0-127)
    [ring_mod, 127].min
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
