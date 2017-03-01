module RPMSpec
  class Parser
    def initialize(file)
      raise RPMSpec::Exception, 'specfile not found.' unless File.exist?(file)
      text = open(file, 'r:UTF-8').read
      @subpackages = RPMSpec::SubPackage.new(text).subpackages
      text = RPMSpec::SubPackage.new(text).strip
      @scriptlets = if RPMSpec::Scriptlet.new(text).scriptlets?
                      RPMSpec::Scriptlet.new(text).scriptlets
                    else
                      nil
                    end
      @text = RPMSpec::Scriptlet.new(text).strip
    end

    def parse(text = @text)
    end

    private

    # find texts contains specified tags and conditional tags
    def find(tag, text = @text)
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
      tags.each { |l| result << l + "\n" }
      result
    end
  end
end
