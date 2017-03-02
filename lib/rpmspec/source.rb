module RPMSpec
  class Source
    def initialize(text)
      @text = text
      @arr = @text.split("\n")
      @struct = Struct.new(:number, :url)
    end

    def sources
      @arr.select { |i| i =~ /^Source(\d+)?:/ }.map do |j|
        arr = j.split(/\s+/)
        number = arr[0].sub(/^Source(\d+)?:/) { Regexp.last_match(1) }
        number = number.empty? ? 0 : number.to_i
        @struct.new(number, arr[1])
      end
    end

    def strip
      line_numbers = []
      @arr.each_with_index do |i, j|
        line_numbers << j if i =~ /^Source(\d+)?:/
      end
      RPMSpec.arr_to_s(@arr[0..line_numbers[0] - 1]) + RPMSpec.arr_to_s(@arr[line_numbers[-1] + 1..-1])
    end

    def self.to_s(arr)
      str = ''
      arr.each { |s| str << 'Source' + s.number.to_s + ":\s\s" + s.url + "\n" }
      str
    end
  end
end
