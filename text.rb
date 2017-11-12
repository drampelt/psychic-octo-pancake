require 'mini_magick'

class Text
	def initialize(word)
		phrase = "I have never seen a #{word} as smart and awesome as this #{word}".split(' ')
		phrase.length.times do |i|
			MiniMagick::Tool::Convert.new do |convert|
				convert.extent "1920x1080"
				convert.background "white"
				convert.fill "black"
				# convert.font "Inconsolata"
				convert.gravity "center"
				convert.pointsize "144"
				convert << "label: #{phrase[i]}"
				convert << "output_#{i.to_s.rjust(3, '0')}.png"
			end
		end
	end
end

Text.new ARGV[0]
