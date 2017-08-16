require File.expand_path('spec_helper', File.dirname(__FILE__))

describe "CursorPaginatedCollection" do
  subject { Sunspot::Search::CursorPaginatedCollection.new [], 10, 20, '*', 'AoIIP4AAACxQcm9maWxlIDEwMTk=' }

  it { expect(subject).to be_an(Array) }

  describe "#send" do
    it 'should allow send' do
      expect { subject.send(:current_cursor) }.to_not raise_error
    end
  end

  describe "#respond_to?" do
    it 'should return true for current_cursor' do
      expect(subject.respond_to?(:current_cursor)).to be(true)
    end
  end

  context "behaves like a WillPaginate::Collection" do
    it { expect(subject.total_entries).to eql(20) }
    it { expect(subject.total_pages).to eql(2) }
    it { expect(subject.current_cursor).to eql('*') }
    it { expect(subject.per_page).to eql(10) }
    it { expect(subject.next_page_cursor).to eql('AoIIP4AAACxQcm9maWxlIDEwMTk=') }
  end

  context "behaves like Kaminari" do
    it { expect(subject.total_count).to eql(20) }
    it { expect(subject.num_pages).to eql(2) }
    it { expect(subject.limit_value).to eql(10) }
    it { expect(subject.first_page?).to be(true) }
    it { expect(subject.last_page?).to be(true) }
  end
end
