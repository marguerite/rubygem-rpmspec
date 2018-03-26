require 'ostruct'

module RPMSpec
  class Parser
    def initialize(file)
      raise 'specfile not found.' unless File.exist?(file)
      text = open(file, 'r:UTF-8').read
      @subpackages = RPMSpec::SubPackage.new(text).subpackages
      @text = RPMSpec::SubPackage.new(text).strip
    end

    def parse
      tags = pick_tags(@text)

      specfile = OpenStruct.new
      specfile.preamble = RPMSpec::Preamble.new(@text).parse
      specfile.macros = RPMSpec::Macro.new(@text).parse
      DEPENDENCY_TAGS.each { |i| fill_dependency(i, specfile) }
      specfile.sources = RPMSpec::Source.new(@text).sources
      specfile.patches = RPMSpec::Patch.new(@text).patches
      specfile.description = RPMSpec::Description.new(@text).parse
      specfile.prep = RPMSpec::Stage.prep(/^%build/, @text)
      specfile.build = RPMSpec::Stage.build(/^%install/, @text)
      specfile.install = RPMSpec::Stage.install(/^%(post|pre$|preun|check|files|changelog)/, @text)
      specfile.check = RPMSpec::Stage.check(/^%(post|pre$|preun|files|changelog)/, @text)
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
        subpkg.name = nameline =~ /-n/ ? nameline.sub!('-n', '').strip! : nameline.strip!
        SUBPACKAGE_TAGS.each { |i| fill_tag(i, subpkg, pick_tags(s)) }
        DEPENDENCY_TAGS.each { |i| fill_dependency(i, subpkg, s) }
        subpkg.description = RPMSpec::Description.new(s).parse
        subpkg.files = RPMSpec::Filelist.new(s).files
        subpkg
      end
    end

    def fill_dependency(tag, ostruct, text = @text)
      ostruct[tag.downcase] = RPMSpec::Dependency.new(dependency_tags(tag, text)).parse(tag)
    end

    def fill_tag(tag, ostruct, arr)
      ostruct[tag.downcase] = replace_tag_value(arr[tag.to_sym], arr, ostruct)
    end

    # it's common that new tag reuse old tags or self/system-defined macros
    # in its definition, so we have to replace them with their actual values.
    # tags: the tags array
    # specfile: the specfile struct contains self-defined macros
    def replace_tag_value(value, tags, specfile)
      return value unless value =~ /%{.*}/
      # replace reused tags first, eg:
      # %{_tmppath}/%{name}-%{version}-build
      arr = find_macros(value)
      # ["_tmppath", "name", "version"]
      reused = SINGLE_TAGS.map(&:downcase) & arr
      reused.each { |r| value = value.gsub('%{' + r + '}', tags[r.capitalize.to_sym]) } unless reused.empty?
      # then replace self-defined macros, eg:
      # %{_tmppath}/tryton-sao-%{majorver}.5-build
      return value if specfile.macros.nil?
      macros = specfile.macros.map(&:name) & find_macros(value)
      macros.each { |m| value = value.gsub('%{' + m + '}', macro_to_hash(specfile.macros)[m]) } unless macros.empty?
      value
    end

    def find_macros(text)
      text.split("%{").reject!(&:empty?).map! { |i| i.match(/(.*)}.*$/)[1] }
    end

    def macro_to_hash(macros)
      h = Hash.new
      macros.each { |i| h[i.name] = i.expression }
      h
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

    # find texts contains specified tags and conditional tags
    def dependency_tags(tag, text)
      # break specfile to lines and strip comments
      arr = text.split("\n").reject! { |i| i.start_with?('#') }
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
