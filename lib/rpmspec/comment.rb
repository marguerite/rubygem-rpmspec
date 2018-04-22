module RPMSpec
  # parse all the comments by default, you can also pass a stop point
  class Comment
    def initialize(text, tag = nil)
      @text = text
      @tag = tag
      @match = if @text =~ /^#.*#{RPMSpec::Subpackage.confident_name(tag)}/m
                 Regexp.last_match[0]
                       .to_enum(:scan, /^#((?!^[\w%]).)*\n/m)
                       .map { Regexp.last_match }
               end
    end

    def preamble(raw = nil)
      m = @match.select { |i| @text =~ /\A#{Regexp.escape(i[0])}/m }
      return if m.empty?
      raw ? m : m[0][0]
    end

    def comments
      m = preamble.nil? ? @match : @match - preamble(1)
      return if m.empty?
      return m.map! { |i| i[0] } unless @tag
      m.select! { |j| @text =~ /#{Regexp.escape(j[0] + @tag)}/m }
      return if m.empty?
      m.map! { |k| k[0] }
    end
  end
end
