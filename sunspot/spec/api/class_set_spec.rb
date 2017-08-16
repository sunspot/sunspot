require "spec_helper"

describe Sunspot::ClassSet do
  it "is enumerable" do
    class1, class2 = double(:name => "Class1"), double(:name => "Class2")

    set = described_class.new
    set << class1 << class2

    expect(set.to_a).to match_array([class1, class2])
  end

  it "replaces classes with the same name" do
    set = described_class.new

    class1 = double(:name => "Class1")
    set << class1
    expect(set.to_a).to eq([class1])

    class1_dup = double(:name => "Class1")
    set << class1_dup
    expect(set.to_a).to eq([class1_dup])
  end
end
