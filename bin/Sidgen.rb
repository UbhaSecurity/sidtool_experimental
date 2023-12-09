MAGIC_NUMBER = "PSID"
VERSION = 0x0002  # Hexadecimal representation of version 0002
DEFAULT_PATTERN_LENGTH = 16
DEFAULT_PLAY_ADDRESS = 0x1000
PADDING_SIZE_BASE = 0x7C
VOICE_CHANGE_POINT = 2
STACCATO_DELAY = 0x00
VOICE_2_SET = 0x0D

# Function to calculate SID note data
def sid_note_data(note)
  [
    (note[:frequency] & 0xFF),
    ((note[:frequency] >> 8) & 0xFF),
    note[:waveform],
    note[:attack_rate],
    note[:decay_rate],
    note[:sustain_level],
    note[:release_rate]
  ]
end

# Function to add arpeggio effect to SID data
def add_arpeggio(sid_data, frequency, pattern_index)
  if pattern_index % 3 == 0
    sid_data.concat([
      (frequency * 2 & 0xFF),
      ((frequency * 2 >> 8) & 0xFF)
    ])
  end
end

# Function to convert a melody to SID data
def convert_melody_to_sid_data(melody, pattern_length = DEFAULT_PATTERN_LENGTH)
  sid_data = []
  previous_note = nil
  voice = 0

  melody.each_with_index do |note, index|
    is_staccato = previous_note && previous_note[:frequency] == note[:frequency]
    sid_data << STACCATO_DELAY if is_staccato
    sid_data.concat(sid_note_data(note))
    add_arpeggio(sid_data, note[:frequency], index) if voice == 1

    if index == melody.size / VOICE_CHANGE_POINT
      voice = 1
      sid_data << VOICE_2_SET
    end

    previous_note = note
  end

  sid_data
end

# Function to create a SID file header
def create_sid_header(data_size, play_address)
  header = "#{MAGIC_NUMBER}#{VERSION.to_s(16).rjust(4, '0')}"
  version_checksum = header.each_byte.sum
  padding_size = PADDING_SIZE_BASE - ((header.size + data_size) % PADDING_SIZE_BASE)

  header + [data_size + 4].pack('V') + [play_address].pack('v') + [version_checksum].pack('v') + "\x00" * padding_size
end

# Function to create a SID file
def create_sid_file(melody, filename, play_address = DEFAULT_PLAY_ADDRESS)
  sid_data = convert_melody_to_sid_data(melody)
  data_size = sid_data.size
  header = create_sid_header(data_size, play_address)

  File.open(filename, 'wb') do |file|
    file.write(header)
    file.write(sid_data.pack('C*'))
  end

  puts "SID file '#{filename}' created successfully."
end

# Example melody data (unchanged)
melody_data = [
  # ... melody data here ...
]


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
create_sid_file(melody_data, "enhanced_melody.sid")
