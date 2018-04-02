require 'ostruct'

module RPMSpec
  class SubPackage
    def initialize(text, **args)
      @text = text
      @args = args
    end

    def parse
      return if @text.scan("%package").empty?
      names.map! do |i|
	index = names.find_index(i)

        s = OpenStruct.new
	s.name = i
	s.desc = descs[index]

	t = tag_texts[index]

        (SINGLE_TAGS + DEPENDENCY_TAGS).each do |i|
	  tag = RPMSpec::Tag.new(t, @args).send(i.downcase.to_sym)
	  s[i.downcase] = tag unless tag.nil?
	end

	s
      end
    end

    def strip
      return @text if @text.scan("%package").empty?
      text = @text.dup
      (names_raw + descs_raw + tag_texts).each {|i| text.sub!(i, "") }
      text
    end

    def inspect
      names_raw.each do |i|
        index = names_raw.find_index(i)
	puts i
	puts tag_texts[index]
	puts descs_raw[index]
      end
    end

    private

    def name_matches
      @text.to_enum(:scan, /%package\s(-n\s)?([a-zA-Z0-9%{}\-_]+)\n/)
           .map { Regexp.last_match }
    end

    def names_raw
      name_matches.map {|i| i[0] }
    end

    def names
      name_matches.map {|i| i[2] }
    end

    def desc_matches
      names.map do |name|
        @text.match(/^%description\s+(-n\s+)?#{name}\n(((?!%prep)(?!%package).)*)\n(\s+)?\n/m)
      end
    end

    def descs_raw
      desc_matches.map {|i| i[0] }
    end

    def descs
      desc_matches.map {|i| i[2] }
    end

    def tag_texts
      names_raw.map do |name|
	@text.match(/#{Regexp.escape(name)}(.*?)^%desc/m)[1]
      end
    end
  end
end
