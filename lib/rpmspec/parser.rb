module RPMSpec
  class Parser
    def initialize(file)
      raise RPMSpec::Exception, 'specfile not found.' unless File.exist?(file)
      text = open(file, 'r:UTF-8').read
      @subpackages = RPMSpec::SubPackage.new(text).subpackages
      @text = RPMSpec::SubPackage.new(text).strip
      @scriptlets = if RPMSpec::Scriptlet.new(text).scriptlets?
                      RPMSpec::Scriptlet.new(text).scriptlets
                    end
      @specfile = Struct.new(:preamble, :macros, :name, :version, :release,
                             :license, :group, :url, :summary, :description,
                             :sources, :patches,
                             :buildrequires, :requires, :provides, :obsoletes,
                             :conflicts, :buildroot, :buildarch, :prep, :build,
                             :install, :check, :scriptlets, :files, :changelog)
    end

    def parse
      preamble = RPMSpec::Preamble.new(@text).parse
      macros = RPMSpec::Macro.new(@text).parse
      buildrequires = RPMSpec::Dependency.new(dependency_tags('BuildRequires')).buildrequires
      requires = RPMSpec::Dependency.new(dependency_tags('Requires')).requires
      sources = RPMSpec::Source.new(@text).sources
      patches = RPMSpec::Patch.new(@text).patches
      description = RPMSpec::Description.new(@text).parse
      init_stages
      prep = Prep.new.parse
      build = Build.new.parse
      install = Install.new.parse
      check = Check.new.parse
      scriptlets = @scriptlets
      if @text =~ /%files/
        filesobj = RPMSpec::Filelist.new(@text)
        files = filesobj.files
      end
      changelog = RPMSpec::Changelog.new(@text).entries
      tags = pick_tags
      @specfile.new(preamble,macros,tags[:name],tags[:version],tags[:release],
                    tags[:license],tags[:group], tags[:url], tags[:summary],
                    description, sources, patches, buildrequires, requires,
                    nil, nil, nil, tags[:buildroot], tags[:buildarch], prep,
                    build, install, check, scriptlets, files, changelog)
    end

    def pick_tags
      tags = {}
      @text.split("\n").select! {|i| i =~ /^[A-Z].*?:/}.each do |j|
        unless j =~ /^(Source|Patch|BuildRequires|Requires|Provides|Obsoletes|Conflicts|Recommends|Suggests|Supplements)/
          key = j.match(/^[A-Z].*?:/)[0].sub(':','').downcase!
          value = j.match(/:.*$/)[0].sub(':','').strip!
          tags[key.to_sym] = value
        end
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
    def dependency_tags(tag)
      # break specfile to lines
      arr = @text.split("\n")
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
        if index > 0 && !line_numbers.include?(index - 1) && arr[index - 1].start_with?('%')
          line_numbers << index - 1
          tags << arr[index - 1]
        end
        tags << l
        if (index < arr.size - 1) && !line_numbers.include?(index + 1) && arr[index + 1].start_with?('%')
          line_numbers << index + 1
          tags << arr[index + 1]
        end
      end
      RPMSpec.arr_to_s(tags)
    end
  end
end
