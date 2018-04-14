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
      s = OpenStruct.new
      s.subpackages = @subpackages
      preamble = RPMSpec::Comment.new(@text).text
      s.preamble = preamble.nil? ? nil : preamble[0][0]
      s.macros = @macros

      TAGS.each do |i|
        tag = RPMSpec::Tag.new(@text, **@args).send(i.downcase.to_sym)
        s[i.downcase] = tag unless tag.nil?
      end

      s.descriptioin = RPMSpec::Subpackage.new(@text, **@args)
                                          .send(:find_description, @text, nil)[3]

      s.prep = RPMSpec::Section.prep(/^%build/, @text)
      s.build = RPMSpec::Section.build(/^%install/, @text)
      s.install = RPMSpec::Section.install(/^%((post|pre)(un)?|files|changelog)/, @text)
      s.check = RPMSpec::Section.check(/^%((post|pre)(un)?|files|changelog)/, @text)

      s.files = RPMSpec::Subpackage.new(@text, **@args).send(:find_files, @text, nil)
      s.scripts = RPMSpec::Subpackage.new(@text, **@args).send(:find_scripts, @text, nil)
      s.changelog = RPMSpec::Change.new(@text).parse

      s
    end

    private

    def macro_args(text)
      args = {}
      @macros.each do |i|
        m = i.text.match(/%define\s([^\s]+)\s('|")?(.*?)('|")?(})?\n/)
        args[m[1].to_sym] = m[3]
      end
      %w(Name Version Release).each do |j|
        tag = RPMSpec::Tag.new(text, **args).send(j.downcase.to_sym)
        args[j.downcase.to_sym] = tag[0].name
      end
      args
    end
  end
end
