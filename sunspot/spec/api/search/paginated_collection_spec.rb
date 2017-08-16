require File.expand_path('spec_helper', File.dirname(__FILE__))

describe "PaginatedCollection" do
  subject { Sunspot::Search::PaginatedCollection.new [], 1, 10, 20 }

  it { expect(subject).to be_an(Array) }

  describe "#send" do
    it 'should allow send' do
      expect { subject.send(:current_page) }.to_not raise_error
    end
  end

  describe "#respond_to?" do
    it 'should return true for current_page' do
      expect(subject.respond_to?(:current_page)).to be(true)
    end
  end

  context "behaves like a WillPaginate::Collection" do
    it { expect(subject.total_entries).to eql(20) }
    it { expect(subject.total_pages).to eql(2) }
    it { expect(subject.current_page).to eql(1) }
    it { expect(subject.per_page).to eql(10) }
    it { expect(subject.previous_page).to be_nil }
    it { expect(subject.prev_page).to be_nil }
    it { expect(subject.next_page).to eql(2) }
    it { expect(subject.out_of_bounds?).not_to be(true) }
    it { expect(subject.offset).to eql(0) }

    it 'should allow setting total_count' do
      subject.total_count = 1
      expect(subject.total_count).to eql(1)
    end

    it 'should allow setting total_entries' do
      subject.total_entries = 1
      expect(subject.total_entries).to eql(1)
    end
  end

  context "behaves like Kaminari" do
    it { expect(subject.total_count).to eql(20) }
    it { expect(subject.num_pages).to eql(2) }
    it { expect(subject.limit_value).to eql(10) }
    it { expect(subject.first_page?).to be(true) }
    it { expect(subject.last_page?).not_to be(true) }
  end
end
