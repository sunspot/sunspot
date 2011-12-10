require File.expand_path('spec_helper', File.dirname(__FILE__))

describe "field grouping" do
  it "sends grouping parameters to solr" do
    session.search Post do
      group :title
    end

    connection.should have_last_search_including(:group, "true")
    connection.should have_last_search_including(:"group.field", "title_ss")
  end

  it "sends grouping limit parameters to solr" do
    session.search Post do
      group :title do
        limit 2
      end
    end

    connection.should have_last_search_including(:"group.limit", 2)
  end

  it "sends grouping sort parameters to solr" do
    session.search Post do
      group :title do
        order_by :average_rating
      end
    end

    connection.should have_last_search_including(:"group.sort", "average_rating_ft asc")
  end
end
