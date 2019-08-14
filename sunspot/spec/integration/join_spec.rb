require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe "searching by joined fields" do
  before :each do
    Sunspot.remove_all!

    @container1 = PhotoContainer.new(:id => 1)
    @container2 = PhotoContainer.new(:id => 2).tap { |c| allow(c).to receive(:id).and_return(2) }
    @container3 = PhotoContainer.new(:id => 3).tap { |c| allow(c).to receive(:id).and_return(3) }

    @picture = Picture.new(:photo_container_id => @container1.id, :description => "one", :published => true)
    @photo1  = Photo.new(:photo_container_id => @container1.id, :description => "two", :published => true)
    @photo2  = Photo.new(:photo_container_id => @container2.id, :description => "three", :published => false)

    Sunspot.index!(@container1, @container2, @photo1, @photo2, @picture)
  end

  it "matches by joined fields" do
    {
      "one"   => [],
      "two"   => [@container1],
      "three" => [@container2]
    }.each do |key, res|
      results = Sunspot.search(PhotoContainer) {
        fulltext(key, :fields => [:photo_description])
      }.results

      expect(results).to eq res
    end
  end

  it "doesn't match by joined fields with the same name from other collections" do
    {
      "one"   => [@container1],
      "two"   => [],
      "three" => []
    }.each do |key, res|
      results = Sunspot.search(PhotoContainer) {
        fulltext(key, :fields => [:picture_description])
      }.results

      expect(results).to eq res
    end
  end

  it "matches by joined fields when using filter queries" do
    {
      :photo_published => [
        [true,  [@container1]],
        [false, [@container2]]
      ],
      :picture_published => [
        [true,  [@container1]],
        [false, []]
      ]
    }.each do |key, data|
      data.each do |(value, res)|
        results = Sunspot.search(PhotoContainer) { with(key, value) }.results

        expect(results).to eq res
      end
    end
  end
end
