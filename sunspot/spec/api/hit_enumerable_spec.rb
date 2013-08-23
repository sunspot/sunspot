require File.join(File.dirname(__FILE__), "spec_helper")

describe Sunspot::Search::HitEnumerable do
  subject do
    Class.new do
      include Sunspot::Search::HitEnumerable
    end.new
  end

  describe "#hits" do
    before do
      subject.stub(:solr_docs).and_return([{"id" => "Post 1", "score" => 3.14}])
      subject.stub(:highlights_for)
    end

    it "retrieves the raw Solr response from #solr_docs and constructs Hit objects" do
      Sunspot::Search::Hit.should_receive(:new).
                           with({"id" => "Post 1", "score" => 3.14}, anything, anything)

      subject.hits
    end

    it "constructs Hit objects with highlights" do
      subject.should_receive(:highlights_for).with({"id" => "Post 1", "score" => 3.14})

      subject.hits
    end

    it "returns only verified hits if :verify => true is passed" do
      Sunspot::Search::Hit.any_instance.stub(:result).and_return(nil)

      subject.hits(:verify => true).should be_empty
    end

    it "returns an empty array if no results are available from Solr" do
      subject.stub(:solr_docs).and_return(nil)

      subject.hits.should == []
    end

    it "provides #populate_hits so that querying for one hit result will eager load the rest" do
      Sunspot::Search::Hit.any_instance.should_receive(:result=)

      subject.populate_hits
    end
  end
end
