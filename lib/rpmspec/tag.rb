module RPMSpec
  # parse RPM tags
  class Tag
    def initialize(text, **args)
      @text = text
      @args = args # macros passed here
    end

    TAGS.each do |t|
      define_method t.downcase.to_sym do
        return unless @text =~ /^#{t}/
        text = add_order(t, @text.dup)
        r = text.to_enum(:scan, /^\d+-#{t}([a-z0-9()]+)?:\s+(.*?)\n/m).map { Regexp.last_match }
        r.map! do |i|
          if DEPS.include?(t) && split_tag(i[2]).instance_of?(Array)
            split_tag(i[2]).map! { |j| to_struct(j, i, text) }
          else
            to_struct(i[2], i, text)
          end
        end.flatten
      end
    end

    private

    def add_order(tag, text, count = 0)
      m = text.to_enum(:scan, /^#{tag}([a-z0-9()]+)?:\s+(.*?)\n/m).map { Regexp.last_match[0] }
      text.sub!(/^#{Regexp.escape(m[0])}/, count.to_s + '-' + m[0])
      if text =~ /^#{tag}/m
        count += 1
        add_order(tag, text, count)
      else
        text
      end
    end

    def to_struct(name, match, text)
      s = OpenStruct.new
      s.name = replace_macro(name)
      s.modifier = match[1] unless match[1].nil?
      conditional = RPMSpec::Conditional.new(text, match[0]).parse
      s.conditional = conditional unless conditional.nil?
      comment = RPMSpec::Comment.new(text, match[0]).text
      s.comment = comment[-1][0] unless comment.nil?
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
