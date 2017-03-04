require 'ostruct'

module RPMSpec
  class Parser
    def initialize(file)
      raise RPMSpec::Exception, 'specfile not found.' unless File.exist?(file)
      text = open(file, 'r:UTF-8').read
      @subpackages = RPMSpec::SubPackage.new(text).subpackages
      @text = RPMSpec::SubPackage.new(text).strip
    end

    def parse
      init_stages
      tags = pick_tags(@text)

      specfile = OpenStruct.new
      specfile.preamble = RPMSpec::Preamble.new(@text).parse
      specfile.macros = RPMSpec::Macro.new(@text).parse
      DEPENDENCY_TAGS.each { |i| fill_dependency(i, specfile) }
      specfile.sources = RPMSpec::Source.new(@text).sources
      specfile.patches = RPMSpec::Patch.new(@text).patches
      specfile.description = RPMSpec::Description.new(@text).parse
      specfile.prep = Prep.new.parse
      specfile.build = Build.new.parse
      specfile.install = Install.new.parse
      specfile.check = Check.new.parse
      specfile.scriptlets = RPMSpec::Scriptlet.new(@text).scriptlets if RPMSpec::Scriptlet.new(@text).scriptlets?
      specfile.files = RPMSpec::Filelist.new(@text).files if @text =~ /%files/
      specfile.subpackages = parse_subpackages(@subpackages)
      specfile.changelog = RPMSpec::Changelog.new(@text).entries
      SINGLE_TAGS.each { |i| fill_tag(i, specfile, tags) }
      specfile
    end

    private

    def parse_subpackages(arr)
      return if arr.nil?
      arr.map! do |s|
        subpkg = OpenStruct.new
        nameline = s.match(/%package(.*?)\n/)[1]
        subpkg.name = nameline =~ /-n/ ? nameline.sub!('-n','').strip! : nameline.strip!
        SUBPACKAGE_TAGS.each { |i| fill_tag(i, subpkg, pick_tags(s)) }
        DEPENDENCY_TAGS.each { |i| fill_dependency(i, subpkg, s) }
        subpkg.description = RPMSpec::Description.new(s).parse
        subpkg.files = RPMSpec::Filelist.new(s).files
        subpkg
      end
    end

    def fill_dependency(tag, ostruct,text=@text)
      ostruct[tag.downcase] = RPMSpec::Dependency.new(dependency_tags(tag,text)).parse(tag)
    end

    def fill_tag(tag, ostruct, arr)
      ostruct[tag.downcase] = arr[tag.to_sym]
    end

    def pick_tags(text)
      tags = {}
      text.split("\n").select! { |i| i =~ /^[A-Z].*?:/ }.each do |j|
        next if j =~ /^(Source|Patch|BuildRequires|Requires|Provides|Obsoletes|Conflicts|Recommends|Suggests|Supplements)/
        key = j.match(/^[A-Z].*?:/)[0].sub(':', '')
        value = j.match(/:.*$/)[0].sub(':', '').strip!
        tags[key.to_sym] = value
      end
      tags
    end

    # create classes for stages
    def init_stages
      stage_struct = Struct.new(:class, :regex, :text)
      s = [stage_struct.new('prep', /^%build/, @text),
           stage_struct.new('build', /^%install/, @text),
           stage_struct.new('install', /^%(post|pre$|preun|check|files|changelog)/, @text),
           stage_struct.new('check', /^%(post|pre$|preun|files|changelog)/, @text)]
      RPMSpec::Stage.new(s).create_stages
    end

    # find texts contains specified tags and conditional tags
    def dependency_tags(tag, text)
      # break specfile to lines
      arr = text.split("\n")
      tags = []
      line_numbers = []
      # loop the lines
      arr.each do |l|
        # must start with the tag
        next unless l.start_with?(tag)
        index = arr.index(l)
        # Find the previous and next line of the tag line
        # to find the possible conditionals.
        # Use line_numbers to hold the line number of the
        # previous and next line, to avoid duplicate case
        # since some line's next line may be other's
        # previous line.
        # The insert order to the tags array is important
        # because we form text later using this order.
        if index > 0 && !line_numbers.include?(index - 1) && arr[index - 1] =~ /^%(if|else|endif)/
          # the 'endif' before the first tag is useless
          unless tags.empty? && arr[index - 1].start_with?('%endif')
            line_numbers << index - 1
            tags << arr[index - 1]
          end
        end
        tags << l
        next unless (index < arr.size - 1) && !line_numbers.include?(index + 1) && arr[index + 1] =~ /^%(if|else|endif)/
        # the 'if' after the last tag is also useless
        unless index == last_tag(tag, arr) && arr[index + 1].start_with?('%if')
          line_numbers << index + 1
          tags << arr[index + 1]
        end
      end
      RPMSpec.arr_to_s(tags)
    end

    def last_tag(tag, arr)
      index = 0
      arr.reverse.each_with_index do |i, j|
        if i.start_with?(tag)
          index = arr.size - 1 - j
          break
        end
      end
      index
    end
  end
end
