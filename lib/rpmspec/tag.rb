module RPMSpec
  # parse RPM tags
  class Tag
    def initialize(text, **args)
      @text = text
      @args = args
    end

    SINGLE_TAGS.each do |t|
      define_method t.downcase.to_sym do
        r = @text.match(/^#{t}:\s+(.*?)\n/m)
	return if @args.nil? && r.nil?
	@args.each do |k, v|
	  return v if t.downcase.to_sym == k
	end
	r[1]
      end
    end

    DEPENDENCY_TAGS.each do |t|
      define_method t.downcase.to_sym do
        r = @text.scan(/^#{t}:\s+(.*?)\n/m)
        return if r.empty?
	r.flatten!.map! do |i|
	  split_tag(i)
	end.flatten.map do |j|
          replace_macro(j)
	end
      end
    end

    private

    def split_tag(t)
      if t.index(",") # BuildRequires: a, b, c
	t.split(",").map(&:strip)
      elsif t =~ /\w\s+\w/ # BuildRequires: a b c
	t.split(/\s+/)
      else
	t
      end
    end

    def replace_macro(t)
      r = t.scan(/%{(.*?)}/)
      unless r.empty?
	r.flatten!.each do |m|
          tag = send(m.to_sym)
	  t.gsub!("%{" + m + "}", tag) unless tag.nil?
        end
      end
      t
    end
  end
end
