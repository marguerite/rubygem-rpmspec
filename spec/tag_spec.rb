require 'spec_helper'
require 'ostruct'

describe RPMSpec do
  t = ""
  RPMSpec::TAGS.each { |i| t += i + ":\sgcc\n" }

  s = OpenStruct.new
  s.name = "gcc"
  s.modifier = nil
  s.conditional = nil

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

  it "can parse comma-style BuildRequires" do
    expect(RPMSpec::Tag.new("BuildRequires: xz, ruby\n").buildrequires).to eq(r)
  end

  it "can parse space-style BuildRequires" do
    expect(RPMSpec::Tag.new("BuildRequires: xz ruby\n").buildrequires).to eq(r)
  end

  it "can parse nil" do
    expect(RPMSpec::Tag.new("BuildRequires: xz\n").requires).to eq(nil)
  end

  it "can expand tags" do
    s.name = "rpmspec-1.0.0"
    expect(RPMSpec::Tag.new("Name: rpmspec\nVersion: 1.0.0\nRequires: %{name}-%{version}\n").requires).to eq([s])
  end

  it "can expand macro" do
    s.name = "libfcitx4_9"
    expect(RPMSpec::Tag.new("Requires: lib%{name}%{libver}\n", name: "fcitx", libver: "4_9").requires).to eq([s])
  end

  it "can identify Requires(post)" do
    s.modifier = "(post)"
    expect(RPMSpec::Tag.new("Requires(post): libfcitx4_9\n").requires).to eq([s])
  end

  it "can identify Source0" do
    s.modifier = "0"
    expect(RPMSpec::Tag.new("Source0: lib%{name}%{libver}\n", name: "fcitx", libver: "4_9").source).to eq([s])
  end
end
