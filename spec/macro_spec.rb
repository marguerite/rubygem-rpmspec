require 'spec_helper'

describe RPMSpec::Macro do
  s = OpenStruct.new
  s.conditional = nil

  %w(define global).each do |i|
    it "can parse %#{i} macros" do
      m = "%#{i} libver '4_9'\n"
      s.text = m
      expect(RPMSpec::Macro.new(m + "Name: fcitx\n").parse).to eq([s])
    end
  end

  it "can parse macro definitions with existence testing" do
    m = "%{!?libver: %define libver '4_9'}\n"
    s.text = m
    expect(RPMSpec::Macro.new(m + "Name: fcitx\n").parse).to eq([s])
  end

  it "can parse conditional macros" do
    m = "%define libver '4_9'\n"
    c = "%if 0%{?suse_version} >= 1320\n"
    s.text = m
    s.conditional = [c]
    expect(RPMSpec::Macro.new(c + m + "%endif\nName: fcitx\n").parse).to eq([s])
  end
end
