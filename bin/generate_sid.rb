# Define the SID header v1
header = "PSID"
version = 1
data_offset = 118  # Size of the header for version 1
load_address = 0  # Default value for load address
init_address = 0  # Default value for init address
play_address = 0  # Default value for play address
songs = 4
start_song = 1
speed = 0  # Default speed setting

# Author, title, and released fields (32 bytes each)
author = "Your Name".ljust(32, "\x00")
title = "Your SID Tune Title".ljust(32, "\x00")
released = "2023-12-31".ljust(32, "\x00")

# Convert header fields to binary format
header_data = [
  header, version, data_offset, load_address, init_address, play_address, songs, start_song, speed,
  author, title, released
].pack("a4 S S S S S S S a32 a32 a32")

# Define SID voice and register settings
voice1 = "\x00\x00\x0f\x09\x00\x07\x00\x00"
voice2 = "\x00\x00\x0f\x07\x00\x07\x00\x00"
voice3 = "\x00\x00\x0f\x05\x00\x07\x00\x00"
bass_track = "\x00\x00\x0f\x04\x00\x07\x00\x00"  # New bass track

# Define a simple song structure with 6 patterns for each voice
song_data = [
  [0, 1, 2, 3, 4, 5],   # Pattern order for voice 1
  [0, 1, 2, 3, 4, 5],   # Pattern order for voice 2
  [0, 1, 2, 3, 4, 5],   # Pattern order for voice 3
  [0, 1, 2, 3, 4, 5],   # Pattern order for bass track
]

# Define note and effect data for each pattern
patterns = []

# Pattern 0 - Melody 1 (Main Track)
patterns << [
  # Voice 1
  [
    [60, 0x40, 0x0F],  # Note: 60, Attack: 64, Release: 15
    [62, 0x40, 0x0F],
    [64, 0x40, 0x0F],
    [65, 0x40, 0x0F],
  ],
  # Voice 2 (Bass Track)
  [
    [36, 0x40, 0x0F],
    [38, 0x40, 0x0F],
    [40, 0x40, 0x0F],
    [41, 0x40, 0x0F],
  ],
  # Voice 3
  [
    [72, 0x40, 0x0F],
    [71, 0x40, 0x0F],
    [69, 0x40, 0x0F],
    [67, 0x40, 0x0F],
  ],
  # Bass Track
  [
    [24, 0x40, 0x0F],  # Adjust the notes and settings for your bass track
    [26, 0x40, 0x0F],
    [28, 0x40, 0x0F],
    [29, 0x40, 0x0F],
  ],
]

# Continue defining more patterns and melodies as needed...
# (Add more patterns and melodies using the same structure)

# Write the SID file
File.open("output.sid", "wb") do |file|
  # Write header data
  file.write(header_data)

  # Write voice settings
  file.write(voice1)
  file.write(voice2)
  file.write(voice3)
  file.write(bass_track)

  # Write song structure
  song_data.each do |voice_order|
    file.write(voice_order.pack("C*"))
  end

  # Write note and effect data for each pattern
  patterns.each do |pattern|
    pattern.each do |voice_data|
      voice_data.each do |note_data|
        file.write(note_data.pack("C*"))
      end
    end
  end
end

puts "SID file 'output.sid' generated successfully!"
