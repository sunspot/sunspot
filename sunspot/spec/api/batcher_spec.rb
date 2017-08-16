require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Batcher do
  it "includes Enumerable" do
    expect(described_class).to include Enumerable
  end

  describe "#each" do
    let(:current) { [:foo, :bar] }
    before { allow(subject).to receive(:current).and_return current }

    it "iterates over current" do
      yielded_values = []

      subject.each do |value|
        yielded_values << value
      end

      expect(yielded_values).to eq current
    end
  end

  describe "adding to current batch" do
    it "#push pushes to current" do
      subject.push :foo
      expect(subject.current).to include :foo
    end

    it "#<< pushes to current" do
      subject.push :foo
      expect(subject.current).to include :foo
    end

    it "#concat concatinates on current batch" do
      subject << :foo
      subject.concat [:bar, :mix]
      is_expected.to include :foo, :bar, :mix
    end
  end


  describe "#current" do
    context "no current" do
      it "starts a new" do
        expect { subject.current }.to change(subject, :depth).by 1
      end

      it "is empty by default" do
        expect(subject.current).to be_empty
      end
    end

    context "with a current" do
      before { subject.start_new }

      it "does not start a new" do
        expect { subject.current }.to_not change(subject, :depth)
      end

      it "returns the same as last time" do
        expect(subject.current).to eq subject.current
      end
    end
  end

  describe "#start_new" do
    it "creates a new batches" do
      expect { 2.times { subject.start_new } }.to change(subject, :depth).by 2
    end

    it "changes current" do
      subject << :foo
      subject.start_new
      is_expected.not_to include :foo
    end
  end

  describe "#end_current" do
    context "no current batch" do
      it "fails" do
        expect { subject.end_current }.to raise_error Sunspot::Batcher::NoCurrentBatchError
      end
    end

    context "with current batch" do
      before { subject.start_new }

      it "changes current" do
        subject << :foo
        subject.end_current
        is_expected.not_to include :foo
      end

      it "returns current" do
        subject << :foo
        expect(subject.end_current).to include :foo
      end
    end
  end

  describe "#batching?" do
    it "is false when depth is 0" do
      expect(subject).to receive(:depth).and_return 0
      is_expected.not_to be_batching
    end

    it "is true when depth is more than 0" do
      expect(subject).to receive(:depth).and_return 1
      is_expected.to be_batching
    end
  end
end
