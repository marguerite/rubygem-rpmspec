module RPMSpec
  class Section
    class << self
      def method_missing(section, *args)
        super unless %i[prep build install check].include?(section)
        regex, text = args
        r = Regexp.new('%' + section.to_s + '(.*?)' + regex.to_s, Regexp::MULTILINE)
        m = text.match(r)
        return if m.nil?
        text.match(r)[1]
      end

      def respond_to_missing?(section)
        %i[prep build install check].include?(section) || super
      end
    end
  end
end
