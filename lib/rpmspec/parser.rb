module RPMSpec
	class Parser
		def initialize(specfile)
			if File.exist?(specfile)
				@specfile = specfile
			else
				raise RPMSpec::Exception.new("specfile not found.")
			end
		end

		def parse
			specfile = Struct.new(:legalheader,:innermacros,:name,:version,:release,:license,:summary,:homepage,:rpmgroup,:sources,:buildrequires,:requires,:buildroot,:description,:prep,:build,:install,:check,:clean,:scriptlets,:files)

			i = 0
			open(@specfile,"r:UTF-8") do |spec|
				spec.each_line do |l|
					p l
				end
			end
		end
	end
end

require './exception.rb'

RPMSpec::Parser.new("./rubygem-gulp-util.spec").parse
