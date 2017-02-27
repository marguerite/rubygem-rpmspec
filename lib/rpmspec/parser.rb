require 'ostruct'

module RPMSpec
  class Parser
    def initialize(specfile)
      raise RPMSpec::Exception, 'specfile not found.' unless File.exist?(specfile)
      @file = open(specfile, 'r:UTF-8').read
    end

    def parse(_file = @file)
      specobj = OpenStruct.new
    end

    private

    def legal_section(file)
      file.match(/.*#\n/m)[0]
    end

    def name_section(file)
      file.match(/Name:.*\n/)[0]
    end

    def version_section(file)
      file.match(/Version:.*\n/)[0]
    end

    def release_section(file)
      file.match(/Release:.*\n/)[0]
    end

    def summary_section(file)
      file.match(/Summary:.*\n/)[0]
    end

    def license_section(file)
      file.match(/License:.*\n/)[0]
    end

    def rpmgroup_section(file)
      file.match(/Group:.*\n/)[0]
    end

    def homepage_section(file)
      file.match(/Url:.*\n/)[0]
    end

    def buildroot_section(file)
      file.match(/BuildRoot:.*\n/)[0]
    end

    def subpackages?(file = @file)
      file.scan('%package').empty? ? false : true
    end

    def find_subpackages(file = @file)
      file.scan(/%package.*?\n\n/m).map do |s|
        s_name = s.match(/%package.*?\n/)[0].sub('%package', '').sub('-n', '').strip!
        # use single line match to find "%description devel"
        s_desc_start = file.match(/%description.*?#{s_name}/)[0]
        s_desc = file.match(/#{s_desc_start}[^%]*\n\n/m)[0]
        # use single line match to find "%file devel"
        s_file_start = file.match(/%file.*?#{s_name}/)[0]
        s_file = file.match(/#{s_file_start}.*?\n\n/m)[0]
        [s, s_desc, s_file]
      end
    end

    def strip_subpackages(file = @file)
      arr = find_subpackages
      arr.each do |s|
        s.each do |i|
          file.sub!(i, '')
        end
      end
      file
    end

    def macros_section(file = @file)
      file.scan(/%define.*?\n/)
    end

    def find_macros(_file = @file)
      macros = {}
      macros_section.each do |s|
        arr = []
        s = s.sub('%define', '').strip!
        arr = if s.index("\t")
                s.split(/\t+/)
              else
                s.split(/\s+/)
              end
        macros[arr[0]] = arr[1]
      end
      macros
    end
  end
end
