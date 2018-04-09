module RPMSpec
  class Parser
    attr_reader :text, :subpackages
    def initialize(file)
      raise 'specfile not found.' unless File.exist?(file)
      text = open(file, 'r:UTF-8').read
      @args = macro_args(text)
      @subpackages = RPMSpec::Subpackage.new(text, **@args).parse
      @text = RPMSpec::Subpackage.new(text, **@args).strip
    end

    def parse
      s = OpenStruct.new
      s.subpackages = @subpackages
      preamble = RPMSpec::Comment.new(@text).text
      s.preamble = preamble.nil? ? nil : preamble[0][0]
      s.macros = RPMSpec::Macro.new(@text).parse
      TAGS.each do |i|
	tag = RPMSpec::Tag.new(@text, **@args).send(i.downcase.to_sym)
	s[i.downcase] = tag unless tag.nil?
      end

      s.description = @text.match(/^%description(\s+)?\n(((?!%prep).)*)/m)[2]
      s.prep = RPMSpec::Section.prep(/^%build/, @text)
      s.build = RPMSpec::Section.build(/^%install/, @text)
      s.install = RPMSpec::Section.install(/^%((post|pre)(un)?|files|changelog)/, @text)
      s.check = RPMSpec::Section.check(/^%((post|pre)(un)?|files|changelog)/, @text)

      s.changelog = RPMSpec::Change.new(@text).parse
      s
    end

    private

    def macro_args(text)
      macros = RPMSpec::Macro.new(text).parse
                             .map! do |i|
        m = i.text.match(/%define\s([^\s]+)\s('|")?(.*?)('|")?(})?\n/)
        [m[1].to_sym, m[3]]
      end.flatten!
      macros = Hash[*macros]
      %w[Name Version Release].each do |j|
        tag = RPMSpec::Tag.new(text, **macros).send(j.downcase.to_sym)
        macros[j.downcase.to_sym] = tag[0].name
      end
      macros
    end
  end
end
