require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot do

  describe "setup" do
    it "should register the class in Sunspot.searchable" do
      Sunspot.setup(User) do
        text :name
      end
      Sunspot.searchable.should_not be_empty
      Sunspot.searchable.should include(User)
    end
  end

  describe "reset!" do
    it "should reset current session" do
      old_session = Sunspot.send(:session)
      Sunspot.reset!(true)
      Sunspot.send(:session).should_not == old_session
    end

    it "should keep keep configuration if specified" do
      Sunspot.config.solr.url = "http://localhost:9999/path/solr"
      config_before_reset = Sunspot.config
      Sunspot.reset!(true)
      Sunspot.config.should == config_before_reset
    end
  end
end
