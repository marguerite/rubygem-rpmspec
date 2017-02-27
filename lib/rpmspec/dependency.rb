module RPMSpec
  class Dependency
    def initialize(file)
      @file = file
    end

    def buildrequires?
      @file.index('BuildRequires') ? true : false
    end

    def buildrequires
      return unless buildrequires?
      s = @file.match(/BuildRequires:.*?\n\n/m)[0]
      cond_part = if s =~ /%if.*%endif/m
                    Regexp.last_match(0)
                  else
                    ''
                  end
      normal_part = s.sub(cond_part, '').split("\n")

      struct = Struct.new(:name, :cond)
      buildrequires = []

      normal_part.each do |l|
        if l.start_with?('BuildRequires:')
          buildrequires << struct.new(l.sub!('BuildRequires:', '').lstrip!, nil)
        end
      end

      return buildrequires if cond_part.empty?

      # from inside to outside, find a full '%if %endif'
      conds = cond_part.scan(/%if.*?%endif/m).map do |s|
                # the fisrt may contain many %if
                if s.scan(/%if.*\n/).size > 1
                  s.match(/\n%if.*?%endif/m)[0].strip!
                else
                  s
                end
              end
      p conds

    end
  end
end

f = open('kcm5-fcitx.spec', 'r:UTF-8').read
RPMSpec::Dependency.new(f).buildrequires
