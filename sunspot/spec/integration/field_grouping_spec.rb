require File.expand_path("../spec_helper", File.dirname(__FILE__))
include SearchHelper

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

    search.group(:title).groups.should include { |g| g.value == "Title1" }
    search.group(:title).groups.should include { |g| g.value == "Title2" }
  end

  it "provides access to the number of matches before grouping" do
    search = Sunspot.search(Post) do
      group :title
    end

    search.group(:title).matches.should == @posts.length
  end

  it "allows grouping by multiple fields" do
    search = Sunspot.search(Post) do
      group :title, :sort_title
    end

    search.group(:title).groups.should_not be_empty
    search.group(:sort_title).groups.should_not be_empty
  end

  it "allows specification of the number of documents per group" do
    search = Sunspot.search(Post) do
      group :title do
        limit 2
      end
    end

    title1_group = search.group(:title).groups.detect { |g| g.value == "Title1" }
    title1_group.hits.length.should == 2
  end

  it "allows specification of the sort within groups" do
    search = Sunspot.search(Post) do
      group :title do
        order_by(:average_rating, :desc)
      end
    end

    highest_ranked_post = @posts.sort_by { |p| -p.ratings_average }.first

    title1_group = search.group(:title).groups.detect { |g| g.value == "Title1" }
    title1_group.hits.first.primary_key.to_i.should == highest_ranked_post.id
  end

  it "provides access to the number of matched groups if ngroups parameter was set" do
    search = Sunspot.search(Post) do
      group :title do
        ngroups true
      end
    end

    search.group(:title).ngroups.should == 2
  end


  it "provides access to the total number of documents in each group" do
    search = Sunspot.search(Post) do
      group :title do
        ngroups true
      end
    end

    title1_group = search.group(:title).groups.detect { |g| g.value == "Title1" }
    title1_group.total.should == 2
    title2_group = search.group(:title).groups.detect { |g| g.value == "Title2" }
    title2_group.total.should == 1
  end

  it "calculates facets using the most relevant document from each group if trancate param is true" do
    search = Sunspot.search(Post) do
      group :title do
        ngroups true
        truncate true
      end
      facet :title
    end
    facet_values(search, :title).should == ['Title1', 'Title2']
    facet_counts(search, :title).should == [1, 1]
  end

end
