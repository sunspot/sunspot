require File.join(File.dirname(__FILE__), 'spec_helper')

describe Sunspot do
  describe "reset!" do
    it "should reset current session" do
      old_session = Sunspot.send(:session)
      Sunspot.reset!

      Sunspot.send(:session).should_not == old_session
    end
    it "should keep keep configuration" do
      Sunspot.config.solr.url = "http://localhost:9999/path/solr"

      config_before_reset = Sunspot.config
      Sunspot.reset!

      Sunspot.config.should == config_before_reset
    end
  end
end