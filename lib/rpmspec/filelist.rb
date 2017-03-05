require 'ostruct'

module RPMSpec
  class Filelist
    def initialize(text)
      @text = text.match(/%files.*?(\n\n|\z)/m)[0].sub!('%files', '')
      @arr = @text.split("\n").reject(&:empty?)
      @file = Struct.new(:file, :permission, :user, :group, :dirpermission, :ghost)
      @defattr = Struct.new(:permission, :user, :group, :dirpermission)
    end

    def files
      files = OpenStruct.new

      # if filelist appended
      unless @arr[0] =~ /^%defattr/
        # it's a subpackage, with '%files name (-f name.lang)?'
        a1 = @arr[0].strip.split("\s")
        a1.each_with_index do |i, j|
          files.list ||= []
          files.list << a1[j + 1] if i == '-f'
        end
      end

      # only one line, usually it indicates every file this package provides
      # is provided via an appended list.
      return files if @arr.size == 1

      # ensure @arr[0] is '%defattr(-,root,root)'
      @arr = @arr[1..-1] if @arr[0] =~ /^[^%]/
      # default file attributes (defattr)
      attributes = @arr[0].sub(/%defattr\((.*)\)/) { Regexp.last_match(1) }.split(',')
      permission, user, group, dirpermission = attributes
      defattr = @defattr.new(permission, user, group, dirpermission)
      files.defattr = defattr

      @arr[1..-1].each do |i|
        a = i.split(/\s+/)
        if i.start_with?('%doc') && a.size > 2
          # '%doc README COPYING' fit this
          a[1..-1].each do |j|
            types.doc ||= []
            types.doc << @file.new(j, permission, user, group, dirpermission, false)
          end
        else
          fileattr = find_attr(a)
          type = find_type(a).sub!('%', '')
          f = find_file(a)
          ghost = ghost?(i)
          files[type.to_sym] ||= []
          if fileattr.nil?
            files[type.to_sym] << @file.new(f, permission, user, group, dirpermission, ghost)
          else
            files[type.to_sym] << @file.new(f, fileattr.permission, fileattr.user, fileattr.group, fileattr.dirpermission, ghost)
          end
        end
      end

      files
    end

    def inspect(struct, name = nil)
      str = ''
      unless struct.list.empty?
        str << (name.nil? ? '%files' : "%files #{name}")
        struct.list.each { |i| str << "\s-f\s" + i }
        str << "\n"
      end
      return str if struct.defattr.nil?
      str << build_attr(struct.defattr, true)
      str << type_to_str('dir', struct.dir, struct.defattr)
      str << type_to_str('doc', struct.doc, struct.defattr)
      str << type_to_str('config', struct.config, struct.defattr)
      str << type_to_str('file', struct.file, struct.defattr)
      str
    end

    private

    def type_to_str(type, arr, defattr)
      str = ''
      arr.each do |s|
        str << "%ghost\s" if s.ghost
        str << '%' + type + "\s" unless type == 'file'
        unless s.permission == defattr.permission &&
               s.user == defattr.user &&
               s.group == defattr.group &&
               s.dirpermission == defattr.dirpermission
          str << build_attr(s)
        end
        str << s.file + "\n"
      end
      str
    end

    def build_attr(struct, default = false)
      str = ''
      str << (default ? '%defattr' : '%attr')
      str << '(' + struct.permission + ',' + struct.user + ',' + struct.group
      str << ',' + struct.dirpermission unless struct.dirpermission.nil?
      str << ')'
      str << (default ? "\n" : "\s")
      str
    end

    def ghost?(file)
      file =~ /%ghost/ ? true : false
    end

    def find_type(arr)
      type = []
      arr.each do |i|
        type << i if i =~ %r{^%(?!(attr|ghost))[^/]+$}
      end
      # in case two types in one line, just use the first
      type.empty? ? '%file' : type[0]
    end

    def find_file(arr)
      normal = []
      arr.each do |i|
        normal << i if i =~ %r{/}
      end
      normal[0]
    end

    def find_attr(arr)
      s = Struct.new(:permission, :user, :group, :dirpermission)
      attributes = nil
      arr.each do |i|
        if i =~ /^%attr/
          attributes = i
          break
        end
      end
      return if attributes.nil?
      a = attributes.sub(/%attr\((.*)\)/) { Regexp.last_match(1) }.split(',')
      a.size > 3 ? s.new(a[0], a[1], a[2], a[3]) : s.new(a[0], a[1], a[2], nil)
    end
  end
end
