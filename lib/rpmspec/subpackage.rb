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
             pkg.desc = find_description(@text, i[2])[3]

             tag_text = find_tag_text(@text, i[0])
             TAGS.each do |j|
               tag = RPMSpec::Tag.new(tag_text, @args).send(j.downcase.to_sym)
               pkg[j.downcase] = tag unless tag.nil?
             end

             pkg.files = find_files(@text, i[2])
             scripts = find_scripts(@text, i[2])
             conditional = RPMSpec::Conditional.new(@text, i[0]).parse
             pkg.scripts = scripts unless scripts.nil?
             pkg.conditional = conditional unless conditional.nil?
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
             files.files[1..-1].each { |t| text.gsub!(/^#{Regexp.escape(t.file)}/, '') if text.index(t.file) }

             next if scripts.nil?
             scripts.each { |s| text.gsub!(s.text, '') }
           end
      # strip the useless self-closed conditional blocks
      text.gsub(/^%if.*?\n%endif.*?\n/m, '')
    end

    private

    def confident_name(name)
      name.nil? ? '' : Regexp.escape(name)
    end

    def find_description(text, name)
      text.match(/^%description(\s+)?(-n\s+)?#{confident_name(name)}\n(((?!%prep)(?!%package).)*)\n(\s+)?\n/m)
    end

    def find_tag_text(text, name)
      text.match(/#{Regexp.escape(name)}(.*?)^%desc/m)[1]
    end

    def find_files(text, name, raw = false)
      m = text.match(/^%files(\s+)?(-n\s+)?#{confident_name(name)}(-f.*?)?\n(((?!%files)(?!%changelog).)*)\n(\s+)?\n/m)
      cond_text = @text.match(/^%if((?!%files).)*?#{Regexp.escape(m[0])}/m)
      conditional = RPMSpec::Conditional.new(cond_text[0], m[0].strip!.gsub!(/%endif\Z/m, '')).parse unless cond_text.nil?
      s = OpenStruct.new
      s.files = parse_file(m[4], raw)
      s.list = m[3].sub!(/-f\s+/, '') unless m[3].nil?
      s.conditional = conditional unless conditional.nil?
      s
    end

    def parse_file(files, raw)
      files.split("\n").map! do |i|
        # ignore %if and %endif
        if i =~ /^%.*if/ || i.empty?
          nil
        else
          cond = RPMSpec::Conditional.new(files, i).parse
          file = if raw
                   i
                 else
                   RPMSpec::Tag.new(@text, @args).send(:replace_macro, i)
                 end
          s = OpenStruct.new
          s.file = file
          s.conditional = cond unless cond.nil?
          s
        end
      end.compact
    end

    def find_scripts(text, name)
      m = text.to_enum(:scan, /^%(pre|post)(un)?\s+(-n\s+)?#{confident_name(name)}(((?!%p)(?!%f)(?!%-).)*)\n/m)
              .map { Regexp.last_match }
      return if m.empty?
      m.map! do |i|
        s = OpenStruct.new
        conditional = RPMSpec::Conditional.new(@text, i[0]).parse
        s.text = i[0]
        s.conditional = conditional unless conditional.nil?
        s
      end
    end
  end
end
