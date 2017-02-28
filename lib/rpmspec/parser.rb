module RPMSpec
  class Parser
    def initialize(file)
      raise RPMSpec::Exception, 'specfile not found.' unless File.exist?(file)
      text = open(file, 'r:UTF-8').read
      @subpackages = has_subpackages?(text) ? find_subpackages(text) : []
      @text = has_subpackages?(text) ? strip_subpackages(@subpackages, text) : text
    end

    def parse(text=@text)
      p @text
    end

    private

    def has_subpackages?(text)
      text.scan('%package').empty? ? false : true
    end

    def find_subpackages(text)
      text.scan(/%package.*?\n\n/m).map do |s|
        s_name = s.match(/%package.*?\n/)[0].sub('%package','').sub('-n','').strip!
        # use single line match to find '%description devel'
        s_desc_start = text.match(/%description.*?#{s_name}/)[0]
        s_desc = text.match(/#{s_desc_start}[^%]*\n\n/m)[0]
        # use single line match to find "%file devel"
        s_file_start = text.match(/%file.*?#{s_name}/)[0]
        s_file = text.match(/#{s_file_start}.*?\n\n/m)[0]
        [s, s_desc, s_file]
      end
    end

    def strip_subpackages(subpackages,text)
      subpackages.each {|s| s.each {|i| text.sub!(i, '') } }
      text
    end

    # find texts contains specified tags and conditional tags
    def find(tag,text=@text)
      # break specfile to lines
      arr = text.split("\n")
      tags = []
      line_numbers = []
      result = ''
      # loop the lines
      arr.each do |l|
        # must start with the tag
        next unless l.start_with?(tag)
        index = arr.index(l)
        # Find the previous and next line of the tag line
        # to find the possible conditionals.
        # Use line_numbers to hold the line number of the
        # previous and next line, to avoid duplicate case
        # since some line's next line may be other's
        # previous line.
        # The insert order to the tags array is important
        # because we form text later using this order.
        if index > 0 && !line_numbers.include?(index - 1) && arr[index - 1].start_with?('%')
          line_numbers << index - 1
          tags << arr[index - 1]
        end
        tags << l
        if (index < arr.size - 1) && !line_numbers.include?(index + 1) && arr[index + 1].start_with?('%')
          line_numbers << index + 1
          tags << arr[index + 1]
        end
      end
      tags.each {|l| result << l + "\n" }
      result
    end
  end
end
