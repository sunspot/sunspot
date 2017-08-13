require File.expand_path('spec_helper', File.dirname(__FILE__))

describe "grouping" do
  it "sends grouping parameters to solr" do
    session.search Post do
      group :title
    end

    expect(connection).to have_last_search_including(:group, "true")
    expect(connection).to have_last_search_including(:"group.field", "title_ss")
  end

  it "sends grouping limit parameters to solr" do
    session.search Post do
      group :title do
        limit 2
      end
    end

    expect(connection).to have_last_search_including(:"group.limit", 2)
  end

  it "sends grouping sort parameters to solr" do
    session.search Post do
      group :title do
        order_by :average_rating
      end
    end

    expect(connection).to have_last_search_including(:"group.sort", "average_rating_ft asc")
  end

  it "sends grouping field parameters to solr" do
    session.search Post do
      group do
        field :title
      end
    end

    expect(connection).to have_last_search_including(:"group.field", "title_ss")
  end

  it "sends grouping query parameters to solr" do
    session.search Post do
      group do
        query 'category 1' do
          with(:category_ids, 1)
        end
      end
    end

    expect(connection).to have_last_search_including(:"group.query", "category_ids_im:1")
  end
end
