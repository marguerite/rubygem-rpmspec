require 'spec_helper'

describe RPMSpec::Conditional do
  let(:text) { "%if 0%{?suse_version} >= 1320\n" \
               "BuildRequires: gcc-c++\n" \
               "%if 0%{?suse_version} > 1320\n" \
               "BuildRequires: libtool\n" \
               "%else\n" \
               "BuildRequires: cmake\n" \
               "BuildRequires: libqt5-qtbase-devel\n" \
               "%if 0%{?sles_version} == 1315 || 0%{?is_opensuse}\n" \
               "BuildRequires: filesystem\n" \
               "%endif\n" \
               "%endif\n" \
               "%else\n" \
               "BuildRequires: kernel-devel\n" \
               "%endif\n" }

  it 'can parse conditionals' do
    result = ["%if 0%{?suse_version} >= 1320\n", "%if 0%{?suse_version} <= 1320\n",
	      "%if 0%{?sles_version} == 1315 || 0%{?is_opensuse}\n"]
    expect(RPMSpec::Conditional.new(text, "BuildRequires: filesystem\n").parse).to eq(result)
  end

  it 'can parse raw conditionals' do
    result = ["%-2-if 0%{?suse_version} >= 1320\n", "%-1-else\n",
	      "%-0-if 0%{?sles_version} == 1315 || 0%{?is_opensuse}\n"]
    expect(RPMSpec::Conditional.new(text, "BuildRequires: filesystem\n").parse(true)).to eq(result)
  end

  it 'can add levels to conditionals in text' do
    result = "%-1-if a\n%-0-if b\nc\n%-0-endif\n%-1-endif\n"
    expect(RPMSpec::Conditional.new("%if a\n%if b\nc\n%endif\n%endif\n", "").text).to eq(result)
  end
end
