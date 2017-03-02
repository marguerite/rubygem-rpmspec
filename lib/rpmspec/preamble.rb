module RPMSpec
  class Preamble
    def initialize(text)
      @text = text
      @arr = @text.split("\n")
    end

    def parse
      preamble = []
      @arr.each do |i|
        break unless i =~ /^#/ || i.empty?
        preamble << i if i =~ /^#/ || i.empty?
      end
      return if preamble.reject(&:empty?).empty?
      RPMSpec.arr_to_s(preamble)
    end

    def strip
      str = parse.nil? ? '' : parse
      @text.sub(str, '')
    end
  end
end
