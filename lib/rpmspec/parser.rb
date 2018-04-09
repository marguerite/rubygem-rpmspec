module RPMSpec
  class Parser
    def initialize(file)
      raise 'specfile not found.' unless File.exist?(file)
      text = open(file, 'r:UTF-8').read
      @macros
      @subpackages = RPMSpec::Subpackage.new(text).parse
      @text = RPMSpec::Subpackage.new(text).strip
    end

    def parse
      specfile = OpenStruct.new
      specfile.preamble
      specfile.prep = RPMSpec::Stage.prep(/^%build/, @text)
      specfile.build = RPMSpec::Stage.build(/^%install/, @text)
      specfile.install = RPMSpec::Stage.install(/^%(post|pre$|preun|check|files|changelog)/, @text)
      specfile.check = RPMSpec::Stage.check(/^%(post|pre$|preun|files|changelog)/, @text)
      specfile.scriptlets = 
      specfile.files = 
      specfile.subpackages = @subpackages
      specfile.changelog = RPMSpec::Change.new(@text).parse
      specfile
    end
  end
end
