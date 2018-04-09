module RPMSpec
  class Change
    def initialize(text)
      @text = text
    end

    def parse
      m = @text.match(/^%changelog\n(.*\Z)/m)
      return if m[1].nil?
      m[1].to_enum(:scan, /^\*((?!^\*).)*/m).map { Regexp.last_match[0] }
    end
  end
end
