module RPMSpec
  class Dependency
    def initialize(file)
      @file = file
      @struct = Struct.new(:name, :conditionals)
    end

    def buildrequires?
      @file.index('BuildRequires') ? true : false
    end

    def requires?
      @file.index(/\nRequires:/) ? true : false
    end

    def buildrequires
      return unless buildrequires?
      # the BuildRequire block
      s = @file.match(/(%if.*?\n)?BuildRequires:.*?\n\n/m)[0]
      # the conditional BuildRequires
      conditionals = s.scan(/%if.*?%endif/m)
      # the normal BuildRequires
      conditionals.each { |i| s.sub!(i, '') } unless conditionals.empty?
      normals = s.split("\n").select! { |i| i.strip.start_with?('BuildRequires') }
                 .map! { |i| @struct.new(i.sub!('BuildRequires:', '').strip!, nil) }
      return normals if conditionals.empty?
      conds = []
      conditionals.each do |i|
        RPMSpec::Conditional.new(i).parse.each do |j|
          j.name.sub!('BuildRequires:', '').strip!
          conds << j
        end
      end
      normals + conds
    end

    def requires
      return unless requires?
    end
  end
end
