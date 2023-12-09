MAGIC_NUMBER = "PSID"
VERSION = 0x0002  # Hexadecimal representation of version 0002
DEFAULT_PATTERN_LENGTH = 16
DEFAULT_PLAY_ADDRESS = 0x1000
PADDING_SIZE_BASE = 0x7C
VOICE_CHANGE_POINT = 2
STACCATO_DELAY = 0x00
VOICE_2_SET = 0x0D
HEADER_SIZE_V2 = 0x007C  # Fixed size of the header for version 2

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
def create_sid_header(melody_length, play_address)
  data_offset = [HEADER_SIZE_V2].pack('n')  # 'n' for 16-bit unsigned big-endian
  load_address = [0].pack('v')              # Assuming load address is in C64 data
  init_address = [play_address].pack('v')   # Assuming init address is play_address
  play_address = [0].pack('v')              # Assuming interrupt handler is used

  songs = [1].pack('v')                     # Number of songs
  start_song = [1].pack('v')                # Default start song
  speed = [0].pack('N')                     # Speed, 32-bit big-endian

  title = "Converted Melody".ljust(32, "\x00")  # Example title
  author = "Composer".ljust(32, "\x00")         # Example author
  released = "2023".ljust(32, "\x00")           # Example release year

  # Concatenating all parts of the header
  header = "#{MAGIC_NUMBER}#{[VERSION].pack('n')}#{data_offset}#{load_address}#{init_address}#{play_address}#{songs}#{start_song}#{speed}#{title}#{author}#{released}"

  header
end

# Function to create a SID file
def create_sid_file(melody, filename, play_address = DEFAULT_PLAY_ADDRESS)
  sid_data = convert_melody_to_sid_data(melody)
  header = create_sid_header(sid_data.size, play_address)

  File.open(filename, 'wb') do |file|
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
create_sid_file(melody_data, "enhanced_melody.sid")
