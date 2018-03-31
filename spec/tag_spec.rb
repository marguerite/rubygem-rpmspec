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
      "BuildRequires: xz ruby\n" \
      "BuildRequires: gcc >= 4.4\n" \
      "BuildRequires: make inittool\n" \
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

  RPMSpec::DEPENDENCY_TAGS[1..-1].each do |tag|
    it "can parse #{tag}" do
      expect(RPMSpec::Tag.new(t).send(tag.downcase.to_sym).join(",")).to eq("gcc")
    end
  end

  it "can parse BuildRequires" do
    expect(RPMSpec::Tag.new(t).buildrequires).to eq(["xz", "ruby", "gcc >= 4.4", "make", "inittool"])
  end

  it "can parse nil" do
    expect(RPMSpec::Tag.new("BuildRequires: xz\n").requires).to eq(nil)
  end
end
