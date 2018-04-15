require 'spec_helper'

describe RPMSpec::Tag do
  t = ''
  RPMSpec::TAGS.each { |i| t += i + ":\sgcc\n" }

  s = OpenStruct.new
  s.name = 'gcc'

  r = %w(xz ruby).map! do |i|
    j = s.dup
    j.name = i
    j
  end

  RPMSpec::TAGS.each do |tag|
    it "can parse #{tag}" do
      expect(RPMSpec::Tag.new(t).send(tag.downcase.to_sym)).to eq([s])
    end
  end

  it 'can parse comma-style BuildRequires' do
    expect(RPMSpec::Tag.new("BuildRequires: xz, ruby\n").buildrequires).to eq(r)
  end

  it 'can parse space-style BuildRequires' do
    expect(RPMSpec::Tag.new("BuildRequires: xz ruby\n").buildrequires).to eq(r)
  end

  it 'can parse nil' do
    expect(RPMSpec::Tag.new("BuildRequires: xz\n").requires).to eq(nil)
  end

  it 'can expand tags' do
    s.name = 'rpmspec-1.0.0'
    expect(RPMSpec::Tag.new("Name: rpmspec\nVersion: 1.0.0\nRequires: %{name}-%{version}\n").requires).to eq([s])
  end

  it 'can expand macro' do
    s.name = 'libfcitx4_9'
    expect(RPMSpec::Tag.new("Requires: lib%{name}%{libver}\n", name: 'fcitx', libver: '4_9').requires).to eq([s])
  end

  it 'can distinguish idential contents' do
    s.name = 'gcc'
    n = s.dup
    n.conditional = ["%if 0%{?suse_version} > 1230\n"]
    expect(RPMSpec::Tag.new("%if 0%{?suse_version} > 1230\nRequires: gcc\n%endif\nRequires: gcc\n").requires).to eq([n, s])
  end

  it 'can recognize Requires(post)' do
    s.modifier = '(post)'
    expect(RPMSpec::Tag.new("Requires(post): gcc\n").requires).to eq([s])
  end

  it 'can recognize Source0' do
    s.name = 'libfcitx4_9'
    s.modifier = '0'
    expect(RPMSpec::Tag.new("Source0: lib%{name}%{libver}\n", name: 'fcitx', libver: '4_9').source).to eq([s])
  end
end
