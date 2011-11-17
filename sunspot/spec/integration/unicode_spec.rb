# encoding: utf-8
require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe "unicode characters" do
  before :each do
    Sunspot.remove_all

    @post = Post.new(:title => "Híghgrøøvé")
    Sunspot.index!(@post)
  end

  it "correctly retrieves the string as UTF-8" do
    Sunspot.search(Post).hits.first.stored(:title).should == "Híghgrøøvé"
  end
end
