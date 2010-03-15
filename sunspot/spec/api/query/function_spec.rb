require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'function query' do
  it "should send query to solr with boost function" do
    session.search Post do
      keywords('pizza') do
        boost(function { :average_rating })
      end
    end
    connection.should have_last_search_including(:bf, 'average_rating_f')
  end

  it "should handle boost function with constant float" do
    session.search Post do
      keywords('pizza') do
        boost(function { 10.5 })
      end
    end
    connection.should have_last_search_including(:bf, '10.5')
  end

  it "should handle boost function with string literal" do
    session.search Post do
      keywords('pizza') do
        boost(function { "hello world" })
      end
    end
    connection.should have_last_search_including(:bf, '"hello world"')
  end
 
  it "should handle arbitrary functions in a function query block" do
    session.search Post do
      keywords('pizza') do
        boost(function { product(:average_rating, 10) })
      end
    end
    connection.should have_last_search_including(:bf, 'product(average_rating_f,10)')
  end
 
  it "should handle nested functions in a function query block" do
    session.search Post do
      keywords('pizza') do
        boost(function { product(:average_rating, sum(:average_rating, 20)) })
      end
    end
    connection.should have_last_search_including(:bf, 'product(average_rating_f,sum(average_rating_f,20))')
  end
end

