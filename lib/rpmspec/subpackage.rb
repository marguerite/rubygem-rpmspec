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
             name = RPMSpec::Tag.new(@text, @args).send(:replace_macro, i[2])
             pkgname = if i[1]
                         name
                       else
                         @args[:name] + '-' + name
                       end
             desc = find_description(@text, i[2])[3]
             tags = find_tags(find_tag_text(@text, i[0]), @args)
             files = find_files(@text, i[2])
             scripts = find_scripts(@text, i[2])
             conditional = RPMSpec::Conditional.new(@text, i[0]).parse

             # "package" could not be "name", tags contains it
             RPMSpec.send(:item_new, package: pkgname,
                          description: desc, files: files,
                          scripts: scripts, conditional: conditional,
                          **tags)
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
             [i[0], desc[0], tag_text].each { |j| text.sub!(j, '') }
             text = strip_files(find_files(@text, i[2], true), i[2], text)
             scripts = find_scripts(@text, i[2])
             next if scripts.nil?
             text = strip_scripts(scripts, text)
           end
      # strip the useless self-closed conditional blocks
      text.gsub(/^%if.*?\n%endif.*?\n/m, '')
    end

    private

    def find_tag_text(text, name)
      text.match(/#{Regexp.escape(name)}(.*?)^%desc/m)[1]
    end

    def find_files(text, name, raw = false)
      m = text.match(/^%files(\s+)?(-n\s+)?#{confident_escape_name(name)}(-f.*?)?\n(((?!%files)(?!%changelog).)*)\n(\s+)?\n/m)
      cond_text = @text.match(/^%if((?!%files).)*?#{Regexp.escape(m[0])}/m)
      conditional = RPMSpec::Conditional.new(cond_text[0], m[0].strip!.gsub!(/%endif\Z/m, '')).parse unless cond_text.nil?
      list = m[3].sub!(/-f\s+/, '') unless m[3].nil?
      RPMSpec.send(:item_new,
                   files: parse_file(m[4], raw),
                   list: list,
                   conditional: conditional)
    end

    def parse_file(files, raw)
      files.split("\n").map! do |i|
        # ignore %if and %endif
        if i =~ /^%.*if/ || i.empty?
          nil
        else
          file = if raw
                   i
                 else
                   RPMSpec::Tag.new(@text, @args).send(:replace_macro, i)
                 end
          RPMSpec.send(:item_new,
                       file: file,
                       conditional: RPMSpec::Conditional.new(files, i).parse)
        end
      end.compact
    end

    def find_scripts(text, name)
      # %p: %post %pre %postun %preun
      # %f: %files
      m = text.to_enum(:scan, /^%(pre|post)(un)?\s+(-n\s+)?#{confident_escape_name(name)}(((?!%p)(?!%f).)*)\n/m)
              .map { Regexp.last_match }
      return if m.empty?
      m.map! do |i|
        RPMSpec.send(:item_new,
                     script: RPMSpec::Conditional.send(:escape, i[0], false),
                     conditional: RPMSpec::Conditional.new(@text, i[0]).parse)
      end
    end

    def strip_files(files, name, text)
      name = confident_escape_name(name)
      # or defattrs will be all stripped
      text.gsub!(/^%files\s+(-n\s+)?#{name}\n(%defattr.*?\n)?/, '')
      files = if files.instance_of?(Array)
                files[1..-1]
              elsif files.instance_of?(OpenStruct)
                files.files[1..-1]
              else
                raise 'Unhandled type of files' + files.inspect
              end
      files.each do |t|
        t = t.file if t.instance_of?(OpenStruct)
        text.gsub!(/^#{Regexp.escape(t)}/, '') if text.index(t)
      end
      text
    end

    def strip_scripts(scripts, text)
      scripts.each do |i|
        if i.instance_of?(String)
          text.gsub!(i, '')
        elsif i.instance_of?(OpenStruct)
          text.gsub!(i.script, '')
        else
          raise 'Unhandled type of scripts' + scripts.inspect
        end
      end
      text
    end
  end
end
