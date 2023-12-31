module SidtoolExperimental
  class RubyFileWriter
    def initialize(synths_for_voices)
      @synths_for_voices = synths_for_voices
    end

    def write_to(path)
      File.open(path, 'w') do |file|
        file.puts '::SYNTHS = ['
        @synths_for_voices.flatten.sort_by(&:start_frame).each do |synth|
          file.puts synth.to_a.inspect + ','
        end
        file.puts ']'
      end
    end
  end
end
