require 'date'
require 'ostruct'

module RPMSpec
  class Changelog
    def initialize(text)
      # sub '%changelog' and "\n" separately to make sure
      # @text and @arr not to be nil too early
      @text = text.match(/%changelog.*\z/m)[0].sub('%changelog', '')
    end

    def entries
      suse? ? entries_suse : entries_fedora
    end

    def inspect(arr)
      suse? ? inspect_suse(arr) : inspect_fedora(arr)
    end

    private

    def entries_suse
      arr = @text.split("\n*").reject!(&:empty?).map!(&:strip!)
      return if arr.empty?
      arr.map! do |entry|
        item = OpenStruct.new
        a, item.changes = entry.split("\n")
        # * Fri Mar 10 2017 axel.braun@gmx.de
        b = a.split("\s")
        item.modification_time = Time.new(b[3], Date::ABBR_MONTHNAMES.index(b[1]),
                                          b[2], 0, 0, 0, '+00:00')
        item.email = b[4]
        item
      end
    end

    def inspect_suse(arr)
      return '%changelog' if arr.nil?
      str = "%changelog\n"
      arr.each do |s|
        head = s.modification_time.strftime(' * %a %b %e %Y ')
        head << s.email + "\n"
        head << s.changes + "\n"
        str << head
      end
      str
    end

    def suse?
      File.exist?('/usr/lib/rpm/suse_macros')
    end

    def entries_fedora
      arr = @text.sub("\n", '').split("\n\n")
      # because we want it nil here
      return if arr.empty?
      arr.map! do |entry|
        s = OpenStruct.new
        head = entry.split("\n")[0]
        others = entry.sub(head, '')
        s.changes = others.split("\n-").reject!(&:empty?).map!(&:strip!)
        a = head.split("\s")
        # *, Sat, Apr, 25, 2015, John, Doe, <example@example.com>, -, 4.2.8.6-1
        s.modification_time = Time.new(a[4], Date::ABBR_MONTHNAMES.index(a[2]), a[3])
        s.packager = head.match(/#{a[4]}(.*)</)[1].strip!
        s.email = head.match(/<(.*)>/)[1]
        s.version = head.match(/\d+\.\d+\.\d+.*$/)[0]
        s
      end
    end

    def inspect_fedora(arr)
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
