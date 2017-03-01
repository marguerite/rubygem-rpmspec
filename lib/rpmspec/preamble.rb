module RPMSpec
  class Preamble
    def initialize(text)
      @text = text
      @arr = @text.split("\n")
    end

    def parse
      str = ''
      preamble = []
      @arr.each do |i|
        break unless i =~ /^#/ || i.empty?
        preamble << i if i =~ /^#/ || i.empty?
      end
      preamble.each { |i| str << i + "\n" }
      str
    end

    def strip
      @text.sub(parse, '')
    end
  end
end
