require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::DataExtractor do
  it "removes special characters from strings" do
    extractor = Sunspot::DataExtractor::AttributeExtractor.new(:name)
    blog      = Blog.new(:name => "Te\x0\x1\x7\x6\x8st\xB\xC\xE Bl\x1Fo\x7fg")

    expect(extractor.value_for(blog)).to eq "Test Blog"
  end

  it "removes special characters from arrays" do
    extractor = Sunspot::DataExtractor::BlockExtractor.new { tags }
    post      = Post.new(:tags => ["Te\x0\x1\x7\x6\x8st Ta\x1Fg\x7f 1", "Test\xB\xC\xE Tag 2"])

    expect(extractor.value_for(post)).to eq ["Test Tag 1", "Test Tag 2"]
  end

  it "removes special characters from hashes" do
    extractor = Sunspot::DataExtractor::Constant.new({ "Te\x0\x1\x7\x6\x8st" => "Ta\x1Fg\x7f" })

    expect(extractor.value_for(Post.new)).to eq({ "Test" => "Tag" })
  end

  it "skips other data types" do
    [
      :"Te\x0\x1\x7\x6\x8st",
      123,
      123.0,
      nil,
      false,
      true,
      Sunspot::Util::Coordinates.new(40.7, -73.5)
    ].each do |value|
      extractor = Sunspot::DataExtractor::Constant.new(value)

      expect(extractor.value_for(Post.new)).to eq value
    end
  end
end
