require 'spec_helper'

describe RPMSpec::Comment do
  f = "Name:\trubygem-rpmspec\n"
  s = "#\n# spec file for package fcitx\n#\n" \
      "# Copyright (c) 2018 SUSE LINUX GmbH, Nuernberg, Germany.\n" \
      "#\n# All modifications and additions to the file contributed by third parties\n" \
	"# remain the property of their copyright owners, unless otherwise agreed\n" \
      "# upon. The license for this file, and modifications and additions to the\n" \
      "# file, is the same license as for the pristine package itself (unless the\n" \
      "# license for the pristine package is not an Open Source License, in which\n" \
	"# case the license is the MIT License). An \"Open Source License\" is a\n" \
	"# license that conforms to the Open Source Definition (Version 1.9)\n" \
	"# published by the Open Source Initiative.\n" \
      "\n# Please submit bugfixes or comments via http://bugs.opensuse.org/\n#\n\n"

  it 'can parse Fedora style preamble' do
    expect(RPMSpec::Comment.new(f).preamble).to eq(nil)
  end

  it 'can parse SUSE style preamble' do
    expect(RPMSpec::Comment.new(s).preamble).to eq(s)
  end

  it 'can parse comments of a patch' do
    r = "#PATCH-FIX-OPENSUSE marguerite@opensuse.org - fix boo#123\n"
    stop = "Patch0: abuild.patch\n"
    c = "#Preamble\nName: fcitx\n#Other useless comments\nVersion: 1.0\n" + r + stop
    expect(RPMSpec::Comment.new(c, stop).comments[-1]).to eq(r)
  end
end
