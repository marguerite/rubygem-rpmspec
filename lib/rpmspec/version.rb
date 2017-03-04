module RPMSpec
  VERSION = '1.0.0'.freeze
  DEPENDENCY_TAGS = %w(BuildRequires Requires Provides
                       Obsoletes Conflicts Recommends
                       Suggests Supplements).freeze
  SINGLE_TAGS = %w(Name Version Release License
                   Group Url Summary BuildRoot
                   BuildArch).freeze
  SUBPACKAGE_TAGS = %w(Version License Group
                       Summary BuildArch).freeze
end
