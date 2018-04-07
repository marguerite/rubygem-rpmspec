module RPMSpec
  # parse all the comments by default, you can also pass a stop point
  class Comment
    attr_reader :text
    def initialize(text, stop = nil)
      r = stop.nil? ? /^#.*/m : /^#.*#{Regexp.escape(stop)}/m
      @text = if text =~ r
                Regexp.last_match[0].to_enum(:scan, /^#((?!^[\w%]).)*\n/m)
                      .map { Regexp.last_match }
              end
    end
  end
end
