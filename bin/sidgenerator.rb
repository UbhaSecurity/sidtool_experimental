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
      (frequency & 0xFF).to_i,  # Frequency (low byte)
      ((frequency >> 8) & 0xFF).to_i,  # Frequency (high byte)
      waveform.to_i,            # Waveform
      attack_rate.to_i,         # Attack rate
      decay_rate.to_i,          # Decay rate
      sustain_level.to_i,       # Sustain level
      release_rate.to_i         # Release rate
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

# Example melody data
melody_data = [
  { frequency: 440, waveform: 0, attack_rate: 15, decay_rate: 10, sustain_level: 5, release_rate: 10 },
  { frequency: 880, waveform: 1, attack_rate: 15, decay_rate: 5, sustain_level: 10, release_rate: 5 },
  # Add more melody data points here
]

# Output SID file
create_sid_file(melody_data, "output.sid")
