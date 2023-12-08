# Constants for SID header
MAGIC_NUMBER = "PSID"

# Function to convert a melody to SID data with envelope support, arpeggios, multiple voices, and song structure
def convert_melody_to_sid_data(melody, pattern_length=16):
    sid_data = []
    previous_note = None
    voice = 0
    pattern_index = 0
    pattern_repeat = 0

    while pattern_repeat < 2:  # Repeat the pattern twice (for demonstration)
        note = melody[pattern_index % len(melody)]

        frequency = note["frequency"]
        waveform = note["waveform"]
        attack_rate = note["attack_rate"]
        decay_rate = note["decay_rate"]
        sustain_level = note["sustain_level"]
        release_rate = note["release_rate"]

        # Check if the current note is the same as the previous note
        is_staccato = previous_note and previous_note["frequency"] == frequency

        # Add a delay for staccato effect
        sid_data.append(0x00 if is_staccato else 0x01)

        # Create SID data for the note
        sid_note_data = [
            (frequency & 0xFF),  # Frequency (low byte)
            ((frequency >> 8) & 0xFF),  # Frequency (high byte)
            waveform,  # Waveform
            attack_rate,  # Attack rate
            decay_rate,  # Decay rate
            sustain_level,  # Sustain level
            release_rate,  # Release rate
        ]

        sid_data.extend(sid_note_data)

        # Arpeggio effect (arpeggios every 3 notes)
        if voice == 1 and pattern_index % 3 == 0:
            arpeggio_note_data = [
                (frequency * 2 & 0xFF),  # Frequency (low byte)
                ((frequency * 2 >> 8) & 0xFF),
            ]
            sid_data.extend(arpeggio_note_data)

        # Switch to Voice 2 after a certain point
        if pattern_index == len(melody) // 2:
            voice = 1
            sid_data.append(0x0D)  # Voice 2 set

        # Update previous_note
        previous_note = note

        # Move to the next pattern index
        pattern_index += 1

        # Check for pattern repetition
        if pattern_index % pattern_length == 0:
            pattern_repeat += 1
            # Skip the rest of the loop iteration if we've reached the end of pattern repetition
            if pattern_repeat >= 2:
                break

    return sid_data

# Function to create a SID file
def create_sid_file(melody, filename, play_address=0x1000, version=2, load_address=0x1000):
    # Calculate data size and padding size based on the length of the melody
    data_size = len(convert_melody_to_sid_data(melody)) * 7
    padding_size = 0x7C - (data_size + 2) % 0x7C

    # Construct the SID file header
    header = f"{MAGIC_NUMBER.ljust(4)}{version.to_bytes(2, 'big').decode('utf-8')}"
    header += f"{(data_size + 2).to_bytes(4, 'big').hex()}{play_address.to_bytes(2, 'big').hex()}"
    header += "00" * padding_size  # Padding

    # Convert the melody to SID data
    sid_data = convert_melody_to_sid_data(melody)

    # Write the header and SID data to the output file in binary mode
    with open(filename, "wb") as file:
        file.write(bytes.fromhex(header))
        file.write(bytes(sid_data))

    print(f"SID file '{filename}' created successfully.")

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
create_sid_file(melody_data, "enhanced_melody.sid", play_address=0x1000, version=2, load_address=0x1000)

