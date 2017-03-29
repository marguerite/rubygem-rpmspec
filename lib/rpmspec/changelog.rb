require 'date'
require 'ostruct'

module RPMSpec
  class Changelog
    def initialize(text)
      # sub '%changelog' and "\n" separately to make sure
      # @text and @arr not to be nil too early
      @text = text.match(/%changelog.*\z/m)[0].sub('%changelog', '')
      @arr = @text.sub("\n", '').split("\n\n")
    end

    def entries
      suse? ? entries_suse : entries_fedora
    end

    def inspect(arr)
      suse? ? inspect_suse(arr) : inspect_fedora(arr)
    end

    private

    def entries_suse
      return if @arr.empty?
      @arr.map! { |entry| entry =~ /^-+\n(.*)$/ ? Regexp.last_match(1) : entry }
          .map! do |entry|
            next if @arr.index(entry).odd?
            item = OpenStruct.new
            a, item.email = entry.split('-').map!(&:strip!)
            # Sat Mar  5 08:31:20 UTC 2016
            b = a.split("\s")
            c = b[3].split(':')
            item.modification_time = Time.new(b[5], Date::ABBR_MONTHNAMES.index(b[1]),
                                              b[2], c[0], c[1], c[2], '+00:00')
            item.changes = @arr[@arr.index(entry) + 1]
            item
          end.compact!
    end

    def inspect_suse(arr)
      return '%changelog' if arr.nil?
      str = "%changelog\n"
      arr.each do |s|
        head = "-------------------------------------------------------------------\n"
        head << s.modification_time.strftime('%a %b %e %H:%M:%S UTC %Y - ')
        head << s.email + "\n\n"
        head << s.changes + "\n\n"
        str << head
      end
      str
    end

    def suse?
      open('/etc/os-release', 'r:UTF-8').read.match(/^ID=(.*)$/)[1] == 'opensuse'
    end

    def entries_fedora
      # because we want it nil here
      return if @arr.empty?
      @arr.map! do |entry|
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
