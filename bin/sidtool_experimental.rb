#!/usr/bin/env ruby
require 'optparse'
require_relative '../lib/sidtool_experimental'
require_relative 'Mos6510'
require_relative 'State'

DEFAULT_FRAMES_TO_PROCESS = 15000

EXPORTERS = {
  'ruby' => SidtoolExperimental::RubyFileWriter,
  'midi' => SidtoolExperimental::MidiFileWriter
}

options = {}
OptionParser.new do |parser|
  parser.banner = 'Usage: sidtool_experimental [options] <inputfile.sid>'

  parser.on('-i', '--info', 'Show file information')
  parser.on('--format FORMAT', 'Output format, "ruby" or "midi"')
  parser.on('-o', '--out FILENAME', 'Output file')
  parser.on('-s', '--song NUMBER', Integer, 'Song number to process (defaults to the start song in the file)')
  parser.on('-f', '--frames NUMBER', Integer, "Number of frames to process (default #{DEFAULT_FRAMES_TO_PROCESS})")
  parser.on_tail('-h', '--help', 'Show this message') do
    puts parser
    exit
  end
  parser.on_tail('--version', 'Show version') do
    puts SidtoolExperimental::VERSION
    exit
  end
end.parse!(into: options)

raise 'Missing input file' if ARGV.empty?
raise 'Too many arguments' if ARGV.length > 1
input_file_path = ARGV.pop
sid_file = SidtoolExperimental::FileReader.read(input_file_path)

output_file_path = options[:out]
show_info = !!options[:info]
raise 'Either provide -i or -o, or I have nothing to do!' unless output_file_path || show_info

selected_format = options[:format] || EXPORTERS.keys.first
exporter_class = EXPORTERS[selected_format]
raise "Invalid format: #{selected_format}. Valid formats: #{EXPORTERS.keys.join(', ')}" unless exporter_class

selected_song = options[:song] || sid_file.start_song
raise 'Song must be at least 1' if selected_song < 1
raise "File only has #{sid_file.songs} songs" if selected_song > sid_file.songs

selected_frames = options[:frames] || DEFAULT_FRAMES_TO_PROCESS

if show_info
  puts "Read #{sid_file.format} version #{sid_file.version} file."
  puts "Name: #{sid_file.name}"
  puts "Author: #{sid_file.author}"
  puts "Released: #{sid_file.released}"
  puts "Songs: #{sid_file.songs} (start song: #{sid_file.start_song})"
end

if output_file_path
  load_address = sid_file.data[0] + (sid_file.data[1] << 8)

  state = Sidtool::State.new
  state.cpu.load(sid_file.data[2..-1], from: load_address)
  state.cpu.start

  play_address = sid_file.play_address
  if play_address == 0
    state.cpu.jsr(sid_file.init_address)
    play_address = (state.cpu.peek(0x0315) << 8) + state.cpu.peek(0x0314)
    STDERR.puts "New play address #{play_address}"
  end

  state.cpu.jsr(sid_file.init_address, selected_song - 1)
  state.run_emulation_loop(selected_frames)

  state.sid6581.stop!
  exporter_class.new(state.sid6581.synths_for_voices).write_to(output_file_path)
  STDERR.puts("Processed #{selected_frames} frames")
end
