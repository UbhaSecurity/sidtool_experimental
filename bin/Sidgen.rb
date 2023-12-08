# Constants for SID header
MAGIC_NUMBER = "PSID"
VERSION = 2

# Function to create a SID file
def create_sid_file(melody, filename, play_address = 0x1000)
  # Calculate data size and padding size based on the length of the melody
  data_size = melody.size * 7
  padding_size = 0x7C - (data_size + 2) % 0x7C

  # Construct the SID file header
  header = "#{MAGIC_NUMBER.ljust(4)}#{VERSION.to_s.rjust(4, '0')}"
  header += [data_size + 2].pack('V')  # Data size (plus 2 for play address)
  header += [play_address].pack('v')  # Play address
  header += "\x00" * padding_size  # Padding

  # Convert the melody to SID data
  sid_data = []

  melody.each do |note|
    frequency = note[:frequency]
    waveform = note[:waveform]
    attack_rate = note[:attack_rate]
    decay_rate = note[:decay_rate]
    sustain_level = note[:sustain_level]
    release_rate = note[:release_rate]

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
  end

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

