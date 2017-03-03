require 'date'

module RPMSpec
  class Changelog
    # openSUSE doesn't write changelog under %changelog
    # so we just parse the Fedora/Upstream style
    def initialize(text)
      # sub '%changelog' and "\n" separately to make sure
      # @text and @arr not to be nil too early
      @text = text.match(/%changelog.*\z/m)[0].sub('%changelog', '')
      @arr = @text.sub("\n", '').split("\n\n")
      @struct = Struct.new(:modification_time, :version, :packager, :email, :changes)
    end

    def entries
      # because we want it nil here
      return if @arr.empty?
      structs = []
      @arr.each do |entry|
        head = entry.split("\n")[0]
        others = entry.sub(head, '')
        items = others.split("\n-").reject!(&:empty?).map!(&:strip!)
        a = head.split("\n")
        # *, Sat, Apr, 25, 2015, John, Doe, <example@example.com>, -, 4.2.8.6-1
        time = Time.new(a[4], Date::ABBR_MONTHNAMES.index(a[2]), a[3])
        packager = a[5] + "\s" + a[6]
        email = a[7][1..-2]
        version = a[9]
        structs = @struct.new(time, version, packager, email, items)
      end
      structs
    end

    def self.to_s(arr)
      return '%changelog' if arr.nil?
      str = "%changelog\n"
      arr.each do |s|
        head = s.modification_time.strftime('* %a %b %d %Y ')
        head << s.packager + "\s"
        head << '<' + s.email + ">\s-\s"
        head << s.version + "\n"
        s.changes.each { |i| head << "-\s" + i + "\n" }
        str << head + "\n"
      end
      str
    end
  end
end
