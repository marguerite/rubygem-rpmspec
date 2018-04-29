class String
  # redefine reverse
  def reverse
    text = dup
    r = /(\d)?%{(\?)?[\w_-]+}(\s[>=<!]+\s[\w"]+)?/m
    conds = text.to_enum(:scan, r).map { Regexp.last_match[0] }
    m = { ">\s" => "<=\s", '>=' => '<', '<=' => '>',
          "<\s" => ">=\s", '==' => '!=', '!=' => '==' }

    if conds.size > 1
      if text =~ /&/
        text.tr!('&', '|')
      else
        text.tr!('|', '&')
      end
    end

    conds.each do |i|
      a = m.keys.map { |k| i.include?(k) }
      if a.include?(true)
        index = a.find_index(true)
        key = m.keys[index]
        text.sub!(i, i.sub(key, m[key]))
      else
        text.sub!(i, '!' + i)
      end
    end

    text
  end
end

module RPMSpec
  # find its conditional for a RPM tag
  class Conditional
    def initialize(text, item)
      t = text.dup
      @text = add_level(t, find_level(t))
      @item = item
    end

    def parse
      m = @text.match(/^%-\d-if.*#{RPMSpec::Conditional.escape(@item)}/m)
      return if m.nil?
      text = m[0]
      r = /^%-\d-if((?!%-\d-if)(?!%-\d-endif).)*%-\d-endif(\s+)?\n/m
      text.to_enum(:scan, r).map { Regexp.last_match }
          .each { |i| text.sub!(i[0], '') }
      ifs = text.scan(/^%-\d-if.*?\n/m)
      return if ifs.empty?
      elses = text.scan(/^%-\d-else.*?\n/m)
      reverse_else(ifs, elses)
    end

    class << self
      # the string itself shouldn't contain any conditional
      def escape(str, regex=true)
        m = str.to_enum(:scan, /^%(end)?if(((?!%if)(?!endif).)*)\n/m).map { Regexp.last_match }
        if m.empty?
          regex ? Regexp.escape(str) : str
        end
        new = str.dup
        m.each { |i| new.sub!(i[0], '') }
        regex ? Regexp.escape(new) : new
      end
    end

    private

    def add_level(text, level)
      replace(text, level)
      if text =~ /^%if/
        level -= 1
        add_level(text, level)
      else
        text
      end
    end

    def find_level(text, level = 0)
      replace(text, level)
      if text =~ /^%if/
        level += 1
        find_level(text, level)
      else
        level
      end
    end

    def replace(text, level)
      text.to_enum(:scan, /^%if((?!%if)(?!%endif).)*%endif\n/m).map { Regexp.last_match[0] }
          .each do |i|
        d = i.dup
        d.sub!('%else', '%-' + level.to_s + '-else') if i =~ /^%else/m
        d.sub!('%if', '%-' + level.to_s + '-if')
        d.sub!('%endif', '%-' + level.to_s + '-endif')
        text.sub!(i, d)
      end
      text
    end

    def reverse_else(ifs, elses)
      elses.each do |i|
        ifs.each_with_index do |m, n|
          next unless m =~ /#{Regexp.escape(i.strip.sub('else', 'if'))}/
          ifs[n] = m.reverse
        end
      end

      ifs.map! { |i| i.sub!(/-\d-/, '') }
    end
  end
end
