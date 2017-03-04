module RPMSpec
  class Preamble
    def initialize(text)
      @arr = text.split("\n")
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
  end
end
