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

    def inspect(arr)
      str = ''
      arr.each { |s| str << 'Source' + s.number.to_s + ":\s\s" + s.url + "\n" }
      str
    end
  end
end
