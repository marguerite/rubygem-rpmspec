module RPMSpec
  class Macro
    def initialize(text)
      @arr = text.split("\n").select {|i| i =~ /^%(define|global|{!\?)/}
      @struct = Struct.new(:indicator, :name, :expression, :test)
    end

    def parse
      return if @arr.empty?
      @arr.map! do |i|
        test = i =~ /^%{!\?/ ? true : false
        indicator = i =~ /%define/ ? 'define' : 'global'
        r = i.match(/#{indicator}\s(.*?)\s(.*$)/)
        name = r[1]
        expression = r[2].end_with?('}') ? r[2][0..-2] : r[2]
        @struct.new(indicator, name, expression, test)
      end
    end

    def to_s(arr)
      str = ''
      arr.each do |i|
        str << "%{!?#{i.name}:\s" if i.test
        str << "%#{i.indicator} #{i.name} #{i.expression}"
        str << '}' if i.test
        str << "\n"
      end
      str
    end
  end
end
