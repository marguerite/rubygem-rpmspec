module RPMSpec
  # parse rpm macros
  class Macro
    def initialize(text)
      @text = text
    end

    def parse
      m = @text.to_enum(:scan, /^(%{!\?[\w\_-]+:\s+)?%(define|global)(.*?)\n(})?/m).map { Regexp.last_match }
      return if m.empty?
      m.map! do |i|
        conditional = RPMSpec::Conditional.new(@text, i[0]).parse
        OpenStruct.new(text: i[0], conditional: conditional)
      end
    end
  end
end
