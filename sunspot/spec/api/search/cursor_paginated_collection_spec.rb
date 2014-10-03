require File.expand_path('spec_helper', File.dirname(__FILE__))

describe "CursorPaginatedCollection" do
  subject { Sunspot::Search::CursorPaginatedCollection.new [], 10, 20, '*', 'AoIIP4AAACxQcm9maWxlIDEwMTk=' }

  it { subject.should be_an(Array) }

  describe "#send" do
    it 'should allow send' do
      expect { subject.send(:current_cursor) }.to_not raise_error
    end
  end

  describe "#respond_to?" do
    it 'should return true for current_cursor' do
      subject.respond_to?(:current_cursor).should be_true
    end
  end

  context "behaves like a WillPaginate::Collection" do
    it { subject.total_entries.should eql(20) }
    it { subject.total_pages.should eql(2) }
    it { subject.current_cursor.should eql('*') }
    it { subject.per_page.should eql(10) }
    it { subject.next_page_cursor.should eql('AoIIP4AAACxQcm9maWxlIDEwMTk=') }
  end

  context "behaves like Kaminari" do
    it { subject.total_count.should eql(20) }
    it { subject.num_pages.should eql(2) }
    it { subject.limit_value.should eql(10) }
    it { subject.first_page?.should be_true }
    it { subject.last_page?.should be_true }
  end
end
