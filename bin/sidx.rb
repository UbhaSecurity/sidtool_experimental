# Approximate SID frequency values for notes
NOTE_FREQUENCIES = {
  'C' => 2000, 'D' => 2200, 'E' => 2400, 
  'F' => 2600, 'G' => 2800, 'A' => 3000, ' ' => 0  # Space for rest
}

# Function to calculate SID note data for multiple voices
def sid_note_data(note_frequencies, waveform, attack_rate, decay_rate, sustain_level, release_rate)
  note_frequencies.map do |frequency|
    [
      (frequency & 0xFF),
      ((frequency >> 8) & 0xFF),
      waveform,
      attack_rate,
      decay_rate,
      sustain_level,
      release_rate
    ]
  end.flatten
end

# Function to convert a melody to SID data for three voices
def convert_melody_to_sid_data(melody)
  sid_data = []
  melody.each_slice(3) do |notes|
    notes = notes.fill(' ', notes.length...3)
    frequencies = notes.map { |note| NOTE_FREQUENCIES[note] }
    waveform = 0x11  # Pulse waveform with gate bit set
    attack_rate, decay_rate, sustain_level, release_rate = [15, 0, 15, 0]  # Example ADSR

    sid_data.concat(sid_note_data(frequencies, waveform, attack_rate, decay_rate, sustain_level, release_rate))
  end
  sid_data
end

# Function to create a SID file header
def create_sid_header(data_length, play_address)
  magic_number = "PSID"
  version = [0x0002].pack('n')  # Version 2
  data_offset = [0x007C].pack('n')  # Header size for version 2
  load_address = [0].pack('v')  # Assuming load address is in C64 data
  init_address = [play_address].pack('v')  # Assuming init address is play_address
  play_address = [0].pack('v')  # Assuming interrupt handler is used

  songs = [1].pack('v')  # Number of songs
  start_song = [1].pack('v')  # Default start song
  speed = [0].pack('N')  # Speed, 32-bit big-endian

  title = "Jingle Bells".ljust(32, "\x00")  # Title
  author = "Composer".ljust(32, "\x00")     # Author
  released = "2023".ljust(32, "\x00")       # Release year

  header = magic_number + version + data_offset + load_address + init_address + play_address + songs + start_song + speed + title + author + released
  header
end

# Function to create a SID file
def create_sid_file(melody, filename, play_address = 0x1000)
  sid_data = convert_melody_to_sid_data(melody)
  header = create_sid_header(sid_data.size, play_address)

  File.open(filename, 'wb') do |file|
    file.write(header)
    file.write(sid_data.pack('C*'))
  end

  puts "SID file '#{filename}' created successfully."
end

# "Jingle Bells" melody distributed across three voices (simplified)
jingle_bells_melody = %w[E E E D C C E D G F E D C G A G F D E E E D C C E D G F E D C G A G F E D C E E E D C C E D G F E D C G A G F D E E E D C C E D G F E D C G A G F E D C]

# Output SID file using all 3 voices
create_sid_file(jingle_bells_melody, "enhanced_melody.sid")
