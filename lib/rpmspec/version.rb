module RPMSpec
  VERSION = '1.0.0'.freeze
  TAGS = %w(Name Version Release License
            Group Url Summary BuildRoot
            BuildArch Source BuildRequires
            Requires Provides Obsoletes
            Conflicts Recommends Suggests
            Supplements Source Patch).freeze
  DEPS = %w(BuildRequires Requires Provides
            Obsoletes Conflicts Recommends
            Suggests Supplements).freeze
end
