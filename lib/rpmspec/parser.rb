module RPMSpec
  class Parser
    def initialize(file)
      raise RPMSpec::Exception, 'specfile not found.' unless File.exist?(file)
      text = open(file, 'r:UTF-8').read
      @subpackages = RPMSpec::SubPackage.new(text).subpackages
      text = RPMSpec::SubPackage.new(text).strip
      @scriptlets = if RPMSpec::Scriptlet.new(text).scriptlets?
                      RPMSpec::Scriptlet.new(text).scriptlets
                    end
      @text = RPMSpec::Scriptlet.new(text).strip
    end

    def parse
      text = @text.dup
      text = RPMSpec::Source.new(text).strip
      text = RPMSpec::Patch.new(text).strip
      text = RPMSpec::Preamble.new(text).strip
      init_stages
      Prep.new.parse + Build.new.parse + Install.new.parse
    end

    # create classes for stages
    def init_stages
      stage_struct = Struct.new(:class, :regex, :text)
      s = [stage_struct.new('prep', /^%build/, @text),
           stage_struct.new('build', /^%install/, @text),
           stage_struct.new('install', /^%(post|pre$|preun|check|files|changelog)/, @text)]
      RPMSpec::Stage.new(s).create_stages
    end

    # find texts contains specified tags and conditional tags
    def dependency_tags(tag, text = @text)
      # break specfile to lines
      arr = text.split("\n")
      tags = []
      line_numbers = []
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
      RPMSpec.arr_to_s(tags)
    end
  end
end
