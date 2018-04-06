require 'ostruct'

module RPMSpec
  # parse RPM tags
  class Tag
    def initialize(text, **args)
      @text = text
      @args = args
    end

    TAGS.each do |t|
      define_method t.downcase.to_sym do
        r = @text.to_enum(:scan, /^#{t}([a-z0-9()]+)?:\s+(.*?)\n/m).map { Regexp.last_match }
        return if r.empty?
        r.map! do |i|
          if split_tag(i[2]).instance_of?(Array)
            split_tag(i[2]).map! { |j| to_struct(j, i) }
          else
            to_struct(i[2], i)
          end
        end.flatten
      end
    end

    private

    def to_struct(name, match)
      s = OpenStruct.new
      s.name = replace_macro(name)
      s.modifier = match[1]
      s.conditional = RPMSpec::Conditional.new(@text, match[0]).parse
      s
    end

    def split_tag(text)
      if text.index(',') # BuildRequires: a, b, c
        text.split(',').map(&:strip)
      elsif text =~ /\w\s+\w/ # BuildRequires: a b c
        text.split(/\s+/)
      else
        text
      end
    end

    def replace_macro(text)
      r = text.to_enum(:scan, /%{(.*?)}/).map { Regexp.last_match[1] }
      unless r.empty?
        r.each do |m|
          tag = if !@args.empty? && @args.keys.include?(m.to_sym)
                  @args[m.to_sym]
                elsif methods.include?(m.to_sym)
                  send(m.to_sym)[0].name
                end
          text.gsub!("%{#{m}}", tag) unless tag.nil?
        end
      end
      text
    end
  end
end
