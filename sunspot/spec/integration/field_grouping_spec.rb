require File.expand_path("../spec_helper", File.dirname(__FILE__))
require File.expand_path("../helpers/search_helper", File.dirname(__FILE__))

describe "field grouping" do
  before :each do
    Sunspot.remove_all

    @posts = [
      Post.new(:title => "Title1", :ratings_average => 4),
      Post.new(:title => "Title1", :ratings_average => 5),
      Post.new(:title => "Title2", :ratings_average => 3)
    ]

    Sunspot.index!(*@posts)
  end

  it "allows grouping by a field" do
    search = Sunspot.search(Post) do
      group :title
    end

    expect(search.group(:title).groups).to include { |g| g.value == "Title1" }
    expect(search.group(:title).groups).to include { |g| g.value == "Title2" }
  end

  it "returns the number of matches unique groups" do
    search = Sunspot.search(Post) do
      group :title
    end

    expect(search.group(:title).total).to eq(2)
  end

  it "provides access to the number of matches before grouping" do
    search = Sunspot.search(Post) do
      group :title
    end

    expect(search.group(:title).matches).to eq(@posts.length)
  end

  it "allows grouping by multiple fields" do
    search = Sunspot.search(Post) do
      group :title, :sort_title
    end

    expect(search.group(:title).groups).not_to be_empty
    expect(search.group(:sort_title).groups).not_to be_empty
  end

  it "allows specification of the number of documents per group" do
    search = Sunspot.search(Post) do
      group :title do
        limit 2
      end
    end

    title1_group = search.group(:title).groups.detect { |g| g.value == "Title1" }
    expect(title1_group.hits.length).to eq(2)
  end

  it "allows specification of the sort within groups" do
    search = Sunspot.search(Post) do
      group :title do
        order_by(:average_rating, :desc)
      end
    end

    highest_ranked_post = @posts.sort_by { |p| -p.ratings_average }.first

    title1_group = search.group(:title).groups.detect { |g| g.value == "Title1" }
    expect(title1_group.hits.first.primary_key.to_i).to eq(highest_ranked_post.id)
  end

  it "allows specification of an ordering function within groups" do
    search = Sunspot.search(Post) do
      group :title do
        order_by_function(:product, :average_rating, -2, :asc)
      end
    end

    highest_ranked_post = @posts.sort_by { |p| -p.ratings_average }.first

    title1_group = search.group(:title).groups.detect { |g| g.value == "Title1" }
    expect(title1_group.hits.first.primary_key.to_i).to eq(highest_ranked_post.id)
  end

  it "allows pagination within groups" do
    search = Sunspot.search(Post) do
      group :title
      paginate :per_page => 1, :page => 2
    end

    expect(search.group(:title).groups.length).to eql(1)
    expect(search.group(:title).groups.first.results).to eq([ @posts.last ])
  end
  
  context "returns a not paginated collection" do
    subject do
      search = Sunspot.search(Post) do
        group :title do
          ngroups false
        end
        paginate :per_page => 1, :page => 2

      end
      search.group(:title).groups
    end

    it { expect(subject.per_page).to      eql(1)   }
    it { expect(subject.total_pages).to   eql(0)   }
    it { expect(subject.current_page).to  eql(2)   }
    it { expect(subject.first_page?).to   be(false) }
    it { expect(subject.last_page?).to    be(true)  }
  end

  context "returns a paginated collection" do
    subject do
      search = Sunspot.search(Post) do
        group :title
        paginate :per_page => 1, :page => 2
      end
      search.group(:title).groups
    end

    it { expect(subject.per_page).to      eql(1)   }
    it { expect(subject.total_pages).to   eql(2)   }
    it { expect(subject.current_page).to  eql(2)   }
    it { expect(subject.first_page?).to   be(false) }
    it { expect(subject.last_page?).to    be(true)  }
  end
end
