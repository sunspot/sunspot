require File.join(File.dirname(__FILE__), "spec_helper")

describe Sunspot::Search::HitEnumerable do
  subject do
    Class.new do
      include Sunspot::Search::HitEnumerable
    end.new
  end

  describe "#hits" do
    before do
      allow(subject).to receive(:solr_docs).and_return([{"id" => "Post 1", "score" => 3.14}])
      allow(subject).to receive(:highlights_for)
    end

    it "retrieves the raw Solr response from #solr_docs and constructs Hit objects" do
      expect(Sunspot::Search::Hit).to receive(:new).
                           with({"id" => "Post 1", "score" => 3.14}, anything, anything)

      subject.hits
    end

    it "constructs Hit objects with highlights" do
      expect(subject).to receive(:highlights_for).with({"id" => "Post 1", "score" => 3.14})

      subject.hits
    end

    it "returns only verified hits if :verify => true is passed" do
      allow_any_instance_of(Sunspot::Search::Hit).to receive(:result).and_return(nil)

      expect(subject.hits(:verify => true)).to be_empty
    end

    it "returns an empty array if no results are available from Solr" do
      allow(subject).to receive(:solr_docs).and_return(nil)

      expect(subject.hits).to eq([])
    end

    it "provides #populate_hits so that querying for one hit result will eager load the rest" do
      expect_any_instance_of(Sunspot::Search::Hit).to receive(:result=)

      subject.populate_hits
    end
  end
end
