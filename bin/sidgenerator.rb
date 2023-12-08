# Constants for SID header
MAGIC_NUMBER = "PSID"
VERSION = 2

# Function to convert a melody to SID data
def convert_melody_to_sid_data(melody)
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

  return sid_data.pack('C*')
end

# Function to create a SID file
def create_sid_file(melody, filename)
  # Construct the SID file header
  data_size = melody.size * 7
  header = "#{MAGIC_NUMBER.ljust(4)}#{VERSION.chr}"
  header += [data_size].pack('V')
  header += "\x00" * 20  # Padding

  # Convert the melody to SID data
  sid_data = convert_melody_to_sid_data(melody)

  # Write the header and SID data to the output file
  File.open(filename, 'wb') do |file|
    file.write(header)
    file.write(sid_data)
  end

  puts "SID file '#{filename}' created successfully."
end

# Example melody data for "The Itsy Bitsy Spider" (simplified)
melody_data = [
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 523, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # C
  { frequency: 523, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # C
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 523, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # C
  { frequency: 523, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # C
  { frequency: 587, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 659, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E

  { frequency: 659, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E
  { frequency: 587, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 523, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # C
  { frequency: 587, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 659, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E
  { frequency: 523, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # C

  { frequency: 659, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E
  { frequency: 659, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E
  { frequency: 587, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 698, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # F
  { frequency: 784, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G

  { frequency: 784, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 698, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # F
  { frequency: 659, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E
  { frequency: 698, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # F
  { frequency: 784, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 659, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E

  { frequency: 523, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # C
  { frequency: 523, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # C
  { frequency: 587, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 659, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E

  { frequency: 784, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 784, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 698, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # F
  { frequency: 587, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 659, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E
  { frequency: 523, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # C
]

# Output SID file
create_sid_file(melody_data, "itsy_bitsy_spider.sid")
