require 'spec_helper'

describe RPMSpec do
  t = "Name: rpmspec\n" \
      "Version: rpmspec\n" \
      "Release: rpmspec\n" \
      "License: rpmspec\n" \
      "Group: rpmspec\n" \
      "Url: rpmspec\n" \
      "Summary: rpmspec\n" \
      "BuildRoot: rpmspec\n" \
      "BuildArch: rpmspec\n" \
      "BuildRequires: gcc\n" \
      "Requires: gcc\n" \
      "Provides: gcc\n" \
      "Obsoletes: gcc\n" \
      "Conflicts: gcc\n" \
      "Recommends: gcc\n" \
      "Suggests: gcc\n" \
      "Supplements: gcc\n"

  RPMSpec::SINGLE_TAGS.each do |tag|
    it "can parse #{tag}" do
      expect(RPMSpec::Tag.new(t).send(tag.downcase.to_sym)).to eq("rpmspec")
    end
  end

  RPMSpec::DEPENDENCY_TAGS.each do |tag|
    it "can parse #{tag}" do
      expect(RPMSpec::Tag.new(t).send(tag.downcase.to_sym).join(",")).to eq("gcc")
    end
  end

  it "can parse comma-style BuildRequires" do
    expect(RPMSpec::Tag.new("BuildRequires: xz, ruby\n").buildrequires).to eq(["xz", "ruby"])
  end

  it "can parse space-style BuildRequires" do
    expect(RPMSpec::Tag.new("BuildRequires: xz ruby\n").buildrequires).to eq(["xz", "ruby"])
  end

  it "can parse nil" do
    expect(RPMSpec::Tag.new("BuildRequires: xz\n").requires).to eq(nil)
  end

  it "can expand macro" do
    expect(RPMSpec::Tag.new("Name: rpmspec\nVersion: 1.0.0\nRequires: %{name}-%{version}\n").requires).to eq(["rpmspec-1.0.0"])
  end

  it "can expand macro using provided ones" do
    expect(RPMSpec::Tag.new("Requires: %{name}-%{version}\n",name:"rpmspec",version:"1.0.0").requires).to eq(["rpmspec-1.0.0"])
  end
end
