module RPMSpec
  class Dependency
    def initialize(text)
      @text = text
    end

    def tag?(tag)
      !@text.scan(/^#{tag}:[^\n]*?\n/).empty?
    end

    def parse(tag)
      return unless tag?(tag)
      s = @text.dup
      # the conditional tags
      conditionals = s.scan(/%if.*?%endif/m)
      # strip conditional tags' contents
      conditionals.each { |i| s.sub!(i, '') } unless conditionals.empty?
      tag_struct = Struct.new(:name, :version, :conditionals, :modifier)
      normals = parse_normal_tag(tag, s, tag_struct)
      return normals if conditionals.empty?
      conds = parse_conditional_tag(tag, conditionals, tag_struct)
      normals + conds
    end

    def inspect(arr, tag)
      str = ''
      arr.each do |s|
        s.conditionals.each { |i| str << "%if\s" + i + "\n" } unless s.conditionals.nil?
        str << if s.modifier.nil?
                 "#{tag}:\s\s#{s.name}\n"
               else
                 "#{tag}(#{s.modifier}):\s\s#{s.name}\n"
               end
        s.conditionals.size.times { str << "%endif\n" } unless s.conditionals.nil?
      end
      str
    end

    private

    def parse_normal_tag(tag, text, struct)
      arr = []
      text.split("\n").reject(&:empty?).each do |i|
        # modifier: modifier to the tag, eg Requires(post)
        modifier = Regexp.last_match(1) if i =~ /\((.*)\):/
        content = i.sub!(/#{tag}.*?:/, '').strip!
        if content =~ /(>|=|<).*$/
          # have an expression Requires: abc > 1.0.0
          version = Regexp.last_match(0)
          name = content.sub!(version, '').strip!
          arr << struct.new(name, version, nil, modifier)
        elsif content =~ /\s+/
          # multiple entries in one line: Requires: example example1
          content.split(/\s+/).each do |j|
            arr << struct.new(j, nil, nil, modifier)
          end
        else
          arr << struct.new(content, nil, nil, modifier)
        end
      end
      arr
    end

    def parse_conditional_tag(tag, conditionals, struct)
      arr = []
      conditionals.each do |i|
        RPMSpec::Conditional.new(i).parse.each do |j|
          modifier = Regexp.last_match(1) if j.name =~ /\((.*)\):/
          content = j.name.sub!(/#{tag}.*?:/, '').strip!
          if content =~ /(>|=|<).*$/
            version = Regexp.last_match(0)
            name = content.sub!(version, '').strip!
            arr << struct.new(name, version, j.conditionals, modifier)
          elsif content =~ /\s+/
            content.split(/\s+/).each do |k|
              arr << struct.new(k, nil, j.conditionals, modifier)
            end
          else
            arr << struct.new(content, nil, j.conditionals, modifier)
          end
        end
      end
      arr
    end
  end
end
