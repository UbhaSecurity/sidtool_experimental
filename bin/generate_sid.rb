# Updated script to generate a valid PSID version 2 file with melodies and patterns

# Define PSID file header for version 2
PSID_HEADER_V2 = [
  'P', 'S', 'I', 'D',   # File ID: "PSID"
  0x02, 0x00,           # Version: 2
  0x7E, 0x00,           # Data Offset
  0x08, 0x00,           # Load Address (0x0800)
  0x08, 0x00,           # Init Address (0x0800)
  0x00,                 # Number of Songs
  0x01,                 # Default Song
  0x00, 0x00, 0x00, 0x00, # Speed
  'M', 'y', ' ', 'S', 'I', 'D', ' ', 'S', 'o', 'n', 'g', 0x00, 0x00, 0x00, 0x00,
  'A', 'u', 't', 'h', 'o', 'r', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  '2', '0', '2', '3', '-', '1', '2', '-', '3', '1', 0x00, 0x00, 0x00, 0x00,
]

# Define arpeggio data (e.g., ascending C major chord)
arpeggio = [0, 4, 7]

# Define slide data (e.g., slide up and down)
slide_up = [0x0A, 0x08, 0x06, 0x04]
slide_down = [0x05, 0x07, 0x09, 0x0B]

# Define portamento effect (e.g., slide between notes)
portamento = [0x00, 0x01, 0x02, 0x03]

# Define volume control (e.g., decrease and increase volume)
volume_down = [0x0F, 0x0D, 0x0B, 0x09, 0x07, 0x05, 0x03, 0x01]
volume_up = [0x01, 0x03, 0x05, 0x07, 0x09, 0x0B, 0x0D, 0x0F]

# Define vibrato effect (e.g., pitch modulation)
vibrato = [0x00, 0x01, 0x02, 0x03]

# Convert notes to frequencies (you may need to adjust these frequencies)
freq_table = [
  4186, 3951, 3729, 3520, 3322, 3136, 2960, 2794, 2637, 2489, 2349, 2217,
  2093, 1976, 1865, 1760, 1661, 1568, 1480, 1397, 1319, 1245, 1175, 1109,
  1047, 987,  931,  880,  831,  784,  740,  699,  659,  622,  587,  554,
  523,  494,  466,  440,  415,  392,  370,  349,  330,  311,  294,  277,
  262,  247,  233,  220,  208,  196,  185,  175,  165,  156,  147,  139,
  131,  123,  117,  110,  104,  98,   93,   87,   82,   78,   73,   69,
  65,   62,   58,   55,   52,   49,   46,   44,   41,   39,   37,   35,
]

# Define patterns (you can add more patterns here)
patterns = [
  [
    # Pattern 1 - Voice 1
    [
      [60, 0x0A, 0x05], # Note: C4, Attack, Release
      [64, 0x08, 0x07], # Note: E4, Attack, Release
      [67, 0x06, 0x09], # Note: G4, Attack, Release
    ],
    # Pattern 1 - Voice 2
    [
      [48, 0x05, 0x07], # Note: C3, Attack, Release
      [52, 0x07, 0x05], # Note: E3, Attack, Release
      [55, 0x09, 0x0B], # Note: G3, Attack, Release
    ],
    # Pattern 1 - Voice 3
    [
      [72, 0x0B, 0x0D], # Note: C5, Attack, Release
      [76, 0x0D, 0x0B], # Note: E5, Attack, Release
      [79, 0x0F, 0x0F], # Note: G5, Attack, Release
    ],
  ],
  # Add more patterns as needed
]

# Initialize the PSID file data with the header
psid_data = PSID_HEADER_V2.dup

# Convert patterns to binary format
patterns.each do |pattern|
  pattern_data = []

  pattern.each_with_index do |voice_data, voice_idx|
    voice_pattern = []

    voice_data.each do |note, attack, release|
      # Convert note value to frequency (adjust as needed)
      frequency = freq_table[note]

      # Build the SID voice data
      sid_data = [
        [0x00, (frequency & 0xFF), ((frequency >> 8) & 0xFF)],
        [attack, release, 0x00],
      ].flatten

      # Add arpeggio, slide, portamento, volume, and vibrato effects
      effects = arpeggio + slide_up + slide_down + portamento + volume_down + volume_up + vibrato
      sid_data += effects

      voice_pattern << sid_data
    end

    pattern_data << voice_pattern
  end

  # Add the voice pattern data to the PSID data
  pattern_data.each do |voice_pattern|
    voice_pattern.each do |sid_data|
      psid_data.concat(sid_data)
    end
  end
end

# Update the PSID file data length field
psid_data[6] = psid_data.length & 0xFF
psid_data[7] = (psid_data.length >> 8) & 0xFF

# Write the PSID data to a file
File.open('output.sid', 'wb') do |file|
  file.write(psid_data.pack("C*"))
end

puts "SID file 'output.sid' generated successfully!"
