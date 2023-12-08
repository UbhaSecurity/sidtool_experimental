# Constants for SID header
MAGIC_NUMBER = "PSID"
VERSION = 2

# Function to convert a melody to SID data with envelope support, arpeggios, multiple voices, and song structure
def convert_melody_to_sid_data(melody)
  sid_data = []
  previous_note = nil
  voice = 0

  melody.each do |note|
    frequency = note[:frequency]
    waveform = note[:waveform]
    attack_rate = note[:attack_rate]
    decay_rate = note[:decay_rate]
    sustain_level = note[:sustain_level]
    release_rate = note[:release_rate]

    # Check if the current note is the same as the previous note
    is_staccato = previous_note && previous_note[:frequency] == frequency

    # Add a delay for staccato effect
    if is_staccato
      sid_data << 0x00
    end

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
    if voice == 1 && melody.index(note) % 3 == 0
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
  end

  return sid_data.pack('C*')
end

# Function to create a SID file with enhanced features
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

# Example melody data with enhanced features
melody_data = [
  # Voice 1
  { frequency: 392, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 523, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # C
  { frequency: 587, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 659, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # E

  # Voice 2 (Arpeggio)
  { frequency: 784, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 880, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # A
  { frequency: 784, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 880, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # A

  # Voice 1 (Continued)
  { frequency: 587, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 523, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # C

  # Voice 2 (Arpeggio)
  { frequency: 784, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 880, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # A
  { frequency: 784, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 880, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # A

  # Switch to Voice 2 (Voice 2 set)
  { frequency: 523, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # C

  # Voice 2 (Arpeggio)
  { frequency: 784, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 880, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # A
  { frequency: 784, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # G
  { frequency: 880, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # A

  # Voice 1 (Continued)
  { frequency: 587, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # D
  { frequency: 523, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 }, # C
]

# Output SID file with enhanced features
create_sid_file(melody_data, "enhanced_melody.sid")
