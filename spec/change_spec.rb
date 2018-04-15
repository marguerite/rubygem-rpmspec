require 'spec_helper'

describe RPMSpec::Change do
  it 'can parse openSUSE changelog' do
    expect(RPMSpec::Change.new("\n%changelog\n").parse).to eq([])
  end

  it 'can parse universal changelog' do
    t = "%changelog\n* Sat Nov 9 i@marguerite.su - 0.0.7\n" \
	"-update\n\n-upstream\n"
    expect(RPMSpec::Change.new(t).parse).to eq([t.sub!("%changelog\n", '')])
  end
end
