module RPMSpec
  # parse RPM tags
  class Tag
    def initialize(text, **args)
      @text = text
      @args = args # macros passed here
    end

    RPMSpec::TAGS.each do |t|
      define_method t.downcase.to_sym do
        return unless @text =~ /^#{t}/
        text = add_order(t, @text.dup)
        r = text.to_enum(:scan, /^\d+-#{t}([a-z0-9()]+)?:\s+(.*?)\n/m).map { Regexp.last_match }
        r.map! do |i|
          if RPMSpec::DEPS.include?(t) && split_tag(i[2]).instance_of?(Array)
            split_tag(i[2]).map! { |j| to_tag(j, i, text) }
          else
            to_tag(i[2], i, text)
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

    def to_tag(name, match, text)
      comment = RPMSpec::Comment.new(text, match[0]).comments
      comment = comment[-1] unless comment.nil?
      RPMSpec.send(:item_new,
                   name: replace_macro(name),
                   modifier: match[1],
                   conditional: RPMSpec::Conditional.new(text, match[0]).parse,
                   comment: comment)
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
                  confident_return_name(send(m.to_sym)[0])
                end
          text.gsub!("%{#{m}}", tag) unless tag.nil?
        end
      end
      text
    end
  end
end
