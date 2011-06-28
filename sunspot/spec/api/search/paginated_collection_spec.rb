require File.expand_path('spec_helper', File.dirname(__FILE__))

describe "PaginatedCollection" do
  subject { Sunspot::Search::PaginatedCollection.new [], 1, 10, 20 }

  it { subject.should be_an(Array) }

  context "behaves like a WillPaginate::Collection" do
    it { subject.total_entries.should eql(20) }
    it { subject.total_pages.should eql(2) }
    it { subject.current_page.should eql(1) }
    it { subject.per_page.should eql(10) }
    it { subject.previous_page.should be_nil }
    it { subject.next_page.should eql(2) }
    it { subject.out_of_bounds?.should_not be_true }
    it { subject.offset.should eql(0) }
  end

  context "behaves like Kaminari" do
    it { subject.total_count.should eql(20) }
    it { subject.num_pages.should eql(2) }
    it { subject.limit_value.should eql(10) }
    it { subject.first_page?.should be_true }
    it { subject.last_page?.should_not be_true }
  end
end
