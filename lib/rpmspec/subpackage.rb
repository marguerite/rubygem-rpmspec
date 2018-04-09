module RPMSpec
  class Subpackage
    def initialize(text, **args)
      @text = text
      @args = args # macros passed here
    end

    def parse
      return unless @text =~ /^%package/m
      @text.to_enum(:scan, /^%package\s+(-n\s+)?([a-zA-Z0-9%{}\-_]+)\n/m)
           .map { Regexp.last_match }
           .map! do |i|
             pkg = OpenStruct.new

             name = RPMSpec::Tag.new(@text, @args).send(:replace_macro, i[2])
             pkg.name = if i[1]
                          name
                        else
                          @args[:name] + '-' + name
                        end
             pkg.desc = find_description(@text, i[2])[2]

             tag_text = find_tag_text(@text, i[0])
             TAGS.each do |j|
               tag = RPMSpec::Tag.new(tag_text, @args).send(j.downcase.to_sym)
               pkg[j.downcase] = tag unless tag.nil?
             end

             pkg.files = find_files(@text, i[2])
             pkg.scripts = find_scripts(@text, i[2])
             pkg.conditional = RPMSpec::Conditional.new(@text, i[0]).parse
             pkg
           end
    end

    def strip
      return @text unless @text =~ /^%package/m
      text = @text.dup
      @text.to_enum(:scan, /^%package\s+(-n\s+)?([a-zA-Z0-9%{}\-_]+)\n/m)
           .map { Regexp.last_match }
           .each do |i|
             desc = find_description(@text, i[2])
             tag_text = find_tag_text(@text, i[0])
             files = find_files(@text, i[2], true)
             scripts = find_scripts(@text, i[2])

             text.sub!(i[0], '')
             text.sub!(desc[0], '')
             text.sub!(tag_text, '')

             # or defattr for the main file block will be stripped too.
             text.gsub!(/^%files\s+(-n\s+)?#{Regexp.escape(i[2])}\n(%defattr.*?\n)?/, '')
             files.text[1..-1].each { |t| text.gsub!(/^#{Regexp.escape(t)}/, '') if text.index(t) }

             next if scripts.nil?
             scripts.each { |s| text.gsub!(s.text, '') }
           end
      text
    end

    private

    def find_description(text, name)
      text.match(/^%description\s+(-n\s+)?#{Regexp.escape(name)}\n(((?!%prep)(?!%package).)*)\n(\s+)?\n/m)
    end

    def find_tag_text(text, name)
      text.match(/#{Regexp.escape(name)}(.*?)^%desc/m)[1]
    end

    def find_files(text, name, raw = false)
      m = text.match(/^%files\s+(-n\s+)?#{Regexp.escape(name)}\n(((?!%files)(?!%changelog).)*)\n(\s+)?\n/m)
      conditional = RPMSpec::Conditional.new(@text, m[0]).parse
      files = if raw
                m[2]
              else
                RPMSpec::Tag.new(@text, @args).send(:replace_macro, m[2])
              end.split("\n")
      OpenStruct.new(text: files, conditional: conditional)
    end

    def find_scripts(text, name)
      m = text.to_enum(:scan, /^%(pre|post)(un)?\s+(-n\s+)?#{Regexp.escape(name)}(((?!%p)(?!%f)(?!%-).)*)\n/m)
              .map { Regexp.last_match }
      return if m.empty?
      m.map! do |i|
        conditional = RPMSpec::Conditional.new(@text, i[0]).parse
        OpenStruct.new(text: i[0], conditional: conditional)
      end
    end
  end
end
