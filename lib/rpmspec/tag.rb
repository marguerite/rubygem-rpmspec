module RPMSpec
  # parse RPM tags
  class Tag
    def initialize(text)
      @text = text
    end

    SINGLE_TAGS.each do |t|
      define_method t.downcase.to_sym do
        r = @text.match(/^#{t}:\s+(.*?)\n/m)
	return if r.nil?
	r[1]
      end
    end

    DEPENDENCY_TAGS.each do |t|
      define_method t.downcase.to_sym do
        r = @text.scan(/^#{t}:\s+(.*?)\n/m)
        return if r.empty?
	r.flatten!.map! do |i|
          # handle BuildRequires: a,b,c
	  if i.index(",")
	    i.split(",").map(&:strip)
	  elsif i =~ /\w\s+\w/
	    i.split(/\s+/)
	  else
	    i
	  end
	end.flatten
      end
    end
  end
end
