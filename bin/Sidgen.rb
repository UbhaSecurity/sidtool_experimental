MAGIC_NUMBER = "PSID"
VERSION = 0x0002  # Hexadecimal representation of version 0002

# Function to convert a melody to SID data with envelope support, arpeggios, multiple voices, and song structure
def convert_melody_to_sid_data(melody, pattern_length = 16)
  sid_data = []
  previous_note = nil
  voice = 0
  pattern_index = 0
  pattern_repeat = 0

  while pattern_repeat < 2  # Repeat the pattern twice (for demonstration)
    note = melody[pattern_index % melody.size]

    frequency = note[:frequency]
    waveform = note[:waveform]
    attack_rate = note[:attack_rate]
    decay_rate = note[:decay_rate]
    sustain_level = note[:sustain_level]
    release_rate = note[:release_rate]

    # Check if the current note is the same as the previous note
    is_staccato = previous_note && previous_note[:frequency] == frequency

    # Add a delay for staccato effect
    sid_data << 0x00 if is_staccato

    # Create SID data for the note
    sid_note_data = [
      (frequency & 0xFF),            # Frequency (low byte)
      ((frequency >> 8) & 0xFF),     # Frequency (high byte)
      waveform,                      # Waveform
      attack_rate,                   # Attack rate
      decay_rate,                    # Decay rate
      sustain_level,                 # Sustain level
      release_rate                   # Release rate
    ]

    sid_data.concat(sid_note_data)

    # Arpeggio effect (arpeggios every 3 notes)
    if voice == 1 && pattern_index % 3 == 0
      arpeggio_note_data = [
        (frequency * 2 & 0xFF),      # Frequency (low byte)
        ((frequency * 2 >> 8) & 0xFF)
      ]
      sid_data.concat(arpeggio_note_data)
    end

    # Switch to Voice 2 after a certain point
    if melody.index(note) == melody.size / 2
      voice = 1
      sid_data << 0x0D  # Voice 2 set
    end

    # Update previous_note
    previous_note = note

    # Move to the next pattern index
    pattern_index += 1

    # Check for pattern repetition
    if pattern_index % pattern_length == 0
      pattern_repeat += 1
      # Skip the rest of the loop iteration if we've reached the end of pattern repetition
      next if pattern_repeat >= 2
    end
  end

  return sid_data
end

# Function to create a SID file
def create_sid_file(melody, filename, play_address = 0x1000)
  # Calculate data size and padding size based on the length of the melody
  data_size = melody.size * 7
  padding_size = 0x7C - ((header.size + data_size) % 0x7C)

  # Construct the SID file header with "505349440002"
  header = "#{MAGIC_NUMBER.ljust(4)}#{VERSION.to_s(16).rjust(4, '0')}"  # Version field is now 2 bytes

  # Calculate the version field's checksum (sum of the ASCII values)
  version_checksum = 0
  header.each_byte { |byte| version_checksum += byte }

  header += [data_size + 4].pack('V')  # Data size (plus 4 for play address and version)
  header += [play_address].pack('v')  # Play address (2 bytes)
  header += [version_checksum].pack('v')  # Version field checksum (2 bytes)
  header += "\x00" * padding_size  # Padding with zero bytes

  # Convert the melody to SID data
  sid_data = convert_melody_to_sid_data(melody)

  # Write the header and SID data to the output file in binary mode
  File.open(filename, 'wb') do |file|  # Use 'wb' for binary mode
    file.write(header)
    file.write(sid_data.pack('C*'))
  end

  puts "SID file '#{filename}' created successfully."
end
# Example melody data with enhanced features
melody_data = [
  # Verse 1
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 294, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 330, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E
  { frequency: 330, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E
  { frequency: 294, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D

  # Chorus 1
  { frequency: 466, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # B
  { frequency: 466, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # B
  { frequency: 440, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # A
  { frequency: 440, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # A
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G

  # Verse 2
  { frequency: 294, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 294, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 330, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E
  { frequency: 330, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E
  { frequency: 294, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D

  # Chorus 2
  { frequency: 466, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # B
  { frequency: 466, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # B
  { frequency: 440, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # A
  { frequency: 440, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # A
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G

  # Chorus 3
  { frequency: 294, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 294, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G

  # Verse 3
  { frequency: 294, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 294, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G

  # Chorus 4
  { frequency: 466, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # B
  { frequency: 466, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # B
  { frequency: 440, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # A
  { frequency: 440, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # A
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
]

# Output SID file with enhanced features
create_sid_file(melody_data, "enhanced_melody.sid", 0x1000)  # Play address set to 0x1000

