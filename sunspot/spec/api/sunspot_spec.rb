require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot do

  describe "setup" do
    it "should register the class in Sunspot.searchable" do
      Sunspot.setup(User) do
        text :name
      end
      expect(Sunspot.searchable).not_to be_empty
      expect(Sunspot.searchable).to include(User)
    end
  end

  describe "reset!" do
    it "should reset current session" do
      old_session = Sunspot.send(:session)
      Sunspot.reset!(true)
      expect(Sunspot.send(:session)).not_to eq(old_session)
    end

    it "should keep keep configuration if specified" do
      Sunspot.config.solr.url = "http://localhost:9999/path/solr"
      config_before_reset = Sunspot.config
      Sunspot.reset!(true)
      expect(Sunspot.config).to eq(config_before_reset)

      # Restore sunspot config after test
      Sunspot.reset!(false)
    end
  end
end
