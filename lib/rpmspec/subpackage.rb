module RPMSpec
  class SubPackage
    def initialize(text)
      @text = text
    end

    def subpackages?
      @text.scan('%package').empty? ? false : true
    end

    def subpackages
      return if subelements.nil?
      subelements.map! { |i| RPMSpec.arr_to_s(i, false) }
    end

    def strip
      return @text if subelements.nil?
      newtext = @text.dup
      subelements.each { |s| s.each { |i| newtext.sub!(i, '') } }
      newtext
    end

    private

    def subelements
      return unless subpackages?
      @text.scan(/%package.*?\n\n/m).map do |s|
        s_name = s.match(/%package.*?\n/)[0].sub('%package', '').sub('-n', '').strip!
        # use single line match to find '%description devel'
        s_desc_start = @text.match(/%description.*?#{s_name}/)[0]
        s_desc = @text.match(/#{s_desc_start}[^%]*\n\n/m)[0]
        # use single line match to find "%file devel"
        s_file_start = @text.match(/%file.*?#{s_name}/)[0]
        s_file = @text.match(/#{s_file_start}.*?\n\n/m)[0]
        [s, s_desc, s_file]
      end
    end
  end
end
