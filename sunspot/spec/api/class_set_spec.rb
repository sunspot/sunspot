require "spec_helper"

describe Sunspot::ClassSet do
  it "is enumerable" do
    class1, class2 = stub(:name => "Class1"), stub(:name => "Class2")

    set = described_class.new
    set << class1 << class2

    set.to_a.should =~ [class1, class2]
  end

  it "replaces classes with the same name" do
    set = described_class.new

    class1 = stub(:name => "Class1")
    set << class1
    set.to_a.should == [class1]

    class1_dup = stub(:name => "Class1")
    set << class1_dup
    set.to_a.should == [class1_dup]
  end
end
