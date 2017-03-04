module RPMSpec
  class Dependency
    def initialize(text)
      @text = text
    end

    def buildrequires
      parse('BuildRequires')
    end

    def tag?(tag)
      @text =~ /^#{tag}:.*\n/ ? true : false
    end

    def requires
      parse('Requires')
    end

    def self.to_s(arr, tag)
      str = ''
      arr.each do |s|
        if s.conditionals.nil?
          if s.modifier.nil?
            str << "#{tag}:\s\s#{s.name}\n"
          else
            str << "#{tag}(#{s.modifier}):\s\s#{s.name}\n"
          end
        else
          s.conditionals.each { |i| str << "%if\s" + i + "\n" }
          if s.modifier.nil?
            str << "#{tag}:\s\s#{s.name}\n"
          else
            str << "#{tag}(#{s.modifier}):\s\s#{s.name}\n"
          end
          s.conditionals.size.times { str << "%endif\n" }
        end
      end
      str
    end

    private

    def parse(tag)
      return unless tag?(tag)
      s = @text.dup
      # the conditional tags
      conditionals = s.scan(/%if.*?%endif/m)
      # strip condtional tags' contents
      conditionals.each { |i| s.sub!(i, '') } unless conditionals.empty?
      tag_struct = Struct.new(:name, :conditionals, :modifier)
      normals = s.split("\n").reject(&:empty?).map! do |i|
                  # modifier: modifier to the tag, eg Requires(post)
                  modifier = Regexp.last_match(1) if i.match(/\((.*)\)/)
                  tag_struct.new(i.sub!(/#{tag}.*?:/, '').strip!, nil, modifier)
                end
      return normals if conditionals.empty?
      conds = []
      conditionals.each do |i|
        RPMSpec::Conditional.new(i).parse.each do |j|
          modifier = Regexp.last_match(1) if j.name.match(/\((.*)\)/)
          name = j.name.sub!(/#{tag}.*?:/, '').strip!
          conds << tag_struct.new(name, j.conditionals, modifier)
        end
      end
      normals + conds
    end
  end
end
