module RPMSpec
  class Patch
    def initialize(text)
      @text = text
      @arr = @text.split("\n")
      @struct = Struct.new(:number, :name, :comment)
    end

    def patches
      patches = []
      @arr.each_with_index do |i, j|
        next unless i =~ /^Patch(\d+)?:/
        comment = find_comments(j, @arr)
        number = i.split(/\s+/)[0]
        number = number.nil? ? 0 : number.to_i
        name = i.gsub(/^Patch.*:(.*)/) { Regexp.last_match(1).strip }
        patches << @struct.new(number, name, comment)
      end
      patches
    end

    def strip
      pa = patches
      newtext = @text.dup
      pa.each do |s|
        newtext.sub!(/^Patch(\d+)?:\s+#{s.name}\n/, '')
        newtext.sub!(/#{s.comment}/, '')
      end
      newtext
    end

    def self.to_s(arr)
      str = ''
      arr.each do |s|
        str << s.comment.strip + "\n" unless s.comment.nil?
        str << 'Patch' + s.number.to_s + ":\s\s" + s.name + "\n"
      end
      str
    end

    private

    def find_comments(index, arr)
      comments = []
      arr[0..index - 1].reverse.each do |i|
        break unless i.start_with?('#')
        comments << i if i.start_with?('#')
      end
      comments.empty? ? nil : arr_to_s(comments.reverse)
    end

    def arr_to_s(arr)
      str = ''
      arr.each { |i| str << i + "\n" }
      str
    end
  end
end
