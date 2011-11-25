# encoding: utf-8
require File.expand_path("../spec_helper", File.dirname(__FILE__))

describe "unicode characters" do
  before :each do
    Sunspot.remove_all

    @post = Post.new(:title => "Híghgrøøvé")
    Sunspot.index!(@post)
  end

  it "correctly retrieves the string as UTF-8" do
    # https://github.com/mwmitchell/rsolr/issues/30
    pending "rsolr 1.0.3 fixes this spec, but also breaks integration with Rails 3.0.10"

    Sunspot.search(Post).hits.first.stored(:title).should == "Híghgrøøvé"
  end
end
