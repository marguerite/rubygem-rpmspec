module RPMSpec
  class Dependency
    def initialize(text)
      @text = text
      @struct = Struct.new(:name, :conditionals)
    end

    def buildrequires?
      @text.index('BuildRequires') ? true : false
    end

    def buildrequires
      parse('BuildRequires')
    end

    def requires?
      @text.index(/\nRequires:/) ? true : false
    end

    def requires
      parse('Requires')
    end

    def self.to_s(arr, tag)
      str = ''
      arr.each do |s|
        if s.conditionals.nil?
          str << tag + ":\s\s" + s.name + "\n"
        else
          s.conditionals.each { |i| str << "%if\s" + i + "\n" }
          str << tag + ":\s\s" + s.name + "\n"
          s.conditionals.size.times { str << "%endif\n" }
        end
      end
      str
    end

    private

    def parse(tag)
      return unless eval(tag.downcase + '?')
      s = @text.dup
      # the conditional tags
      conditionals = s.scan(/%if.*?%endif/m)
      # the normal tags
      conditionals.each { |i| s.sub!(i, '') } unless conditionals.empty?
      normals = s.split("\n").select! { |i| i.strip.start_with?(tag) }
                 .map! { |i| @struct.new(i.sub!(tag + ':', '').strip!, nil) }
      return normals if conditionals.empty?
      conds = []
      conditionals.each do |i|
        RPMSpec::Conditional.new(i).parse.each do |j|
          j.name.sub!(tag + ':', '').strip!
          conds << j
        end
      end
      normals + conds
    end
  end
end
