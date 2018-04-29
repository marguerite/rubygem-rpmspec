module RPMSpec
  # parse all the comments by default, you can also pass a stop point
  class Comment
    def initialize(text, tag = nil)
      @text = text
      @tag = tag
      @match = if @text =~ /^#.*#{confident_escape_name(tag)}/m
                 Regexp.last_match[0]
                       .to_enum(:scan, /^#((?!^[\w%]).)*\n/m)
                       .map { Regexp.last_match }
               end
    end

    def preamble(raw = nil)
      return if @match.nil?
      m = @match.select { |i| @text =~ /\A#{Regexp.escape(i[0])}/m }
      return if m.empty?
      raw ? m : m[0][0]
    end

    def comments
      return if @match.nil?
      m = @match - confident_array(preamble(1))
      return m.map! { |i| i[0] } unless @tag
      m.select! { |j| @text =~ /#{Regexp.escape(j[0] + @tag)}/m }
      return if m.empty?
      m.map! { |k| k[0] }
    end

    private

    def confident_array(value)
      value.nil? ? [] : value
    end
  end
end
