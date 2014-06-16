require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe "geospatial search" do
  describe "filtering by radius" do
    before :all do
      Sunspot.remove_all

      @post = Post.new(:title       => "Howdy",
                       :coordinates => Sunspot::Util::Coordinates.new(32, -68))
      Sunspot.index!(@post)
    end

    it "matches posts within the radius" do
      results = Sunspot.search(Post) {
        with(:coordinates_new).in_radius(32, -68, 1)
      }.results

      results.should include(@post)
    end

    it "filters out posts not in the radius" do
      results = Sunspot.search(Post) {
        with(:coordinates_new).in_radius(33, -68, 1)
      }.results

      results.should_not include(@post)
    end

    it "allows conjunction queries" do
      results = Sunspot.search(Post) {
        any_of do
          with(:coordinates_new).in_radius(32, -68, 1)
          with(:coordinates_new).in_radius(35, 68, 1)
        end
      }.results

      results.should include(@post)
    end
  end

  describe "filtering by bounding box" do
    before :all do
      Sunspot.remove_all

      @post = Post.new(:title       => "Howdy",
                       :coordinates => Sunspot::Util::Coordinates.new(32, -68))
      Sunspot.index!(@post)
    end

    it "matches post within the bounding box" do
      results = Sunspot.search(Post) {
        with(:coordinates_new).in_bounding_box [31, -69], [33, -67]
      }.results

      results.should include(@post)
    end

    it "filters out posts not in the bounding box" do
      results = Sunspot.search(Post) {
        with(:coordinates_new).in_bounding_box [20, -70], [21, -69]
      }.results

      results.should_not include(@post)
    end
  end

  describe "ordering by geodist" do
    before :all do
      Sunspot.remove_all

      @posts = [
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(34, -68)),
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(33, -68)),
        Post.new(:title => "Howdy", :coordinates => Sunspot::Util::Coordinates.new(32, -68))
      ]

      Sunspot.index!(@posts)
    end

    it "orders posts by distance ascending" do
      results = Sunspot.search(Post) {
        order_by_geodist(:coordinates_new, 32, -68)
      }.results

      results.should == @posts.reverse
    end

    it "orders posts by distance descending" do
      results = Sunspot.search(Post) {
        order_by_geodist(:coordinates_new, 32, -68, :desc)
      }.results

      results.should == @posts
    end
  end
end
