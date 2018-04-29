module RPMSpec
  class Parser
    def initialize(file)
      raise 'specfile not found.' unless File.exist?(file)
      text = open(file, 'r:UTF-8').read
      @macros = RPMSpec::Macro.new(text).parse
      @args = macro_args(text)
      @subpackages = RPMSpec::Subpackage.new(text, **@args).parse
      @text = RPMSpec::Subpackage.new(text, **@args).strip
    end

    def parse
      preamble = RPMSpec::Comment.new(@text).preamble
      tags = find_tags(@text, @args)
      desc = find_description(@text, nil)[3]
      sections = process_sections
      files = RPMSpec::Subpackage.new(@text, **@args).send(:find_files, @text, nil)
      scripts = RPMSpec::Subpackage.new(@text, **@args).send(:find_scripts, @text, nil)
      change = RPMSpec::Change.new(@text).parse
      RPMSpec.send(:item_new, subpackages: @subpackages,
                   preamble: preamble, macros: @macros,
                   description: desc, files: files,
                   scripts: scripts, changelog: change, **tags.merge!(sections))
    end

    private

    def process_sections
      r = /^%((post|pre)(un)?|files|changelog)/
      a = %i[prep build install check]
      Hash[*a.map! do |i|
        index = a.index(i)
        if index > 1
          [i, RPMSpec::Section.send(i, r, @text)]
        else
          regex = Regexp.new("^%" + a[index + 1].to_s)
          [i, RPMSpec::Section.send(i, regex, @text)]
        end
      end.flatten!]
    end

    def macro_args(text)
      args = {}
      @macros.each do |i|
        m = i.text.match(/%define\s([^\s]+)\s('|")?(.*?)('|")?(})?\n/)
        args[m[1].to_sym] = m[3]
      end
      %w(Name Version Release).each do |j|
        tag = RPMSpec::Tag.new(text, **args).send(j.downcase.to_sym)
        args[j.downcase.to_sym] = confident_return_name(tag[0])
      end
      args
    end
  end
end
