module RPMSpec
  class Description
    def initialize(text)
      @match = text.match(/%description.*?(%prep|%files)/m)
    end

    def parse
      @match[0].sub!(@match[1], '').sub!(/%description.*?\n/, '')
    end
  end
end
