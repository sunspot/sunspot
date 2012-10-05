require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'function query' do
  it "should send query to solr with boost function" do
    session.search Post do
      keywords('pizza') do
        boost(function { :average_rating })
      end
    end
    connection.should have_last_search_including(:bf, 'average_rating_ft')
  end

  it "should send query to solr with boost function and boost amount" do
    session.search Post do
      keywords('pizza') do
        boost(function { :average_rating }^5)
      end
    end
    connection.should have_last_search_including(:bf, 'average_rating_ft^5')
  end

  it "should handle boost function with constant float" do
    session.search Post do
      keywords('pizza') do
        boost(function { 10.5 })
      end
    end
    connection.should have_last_search_including(:bf, '10.5')
  end

  it "should handle boost function with constant float and boost amount" do
    session.search Post do
      keywords('pizza') do
        boost(function { 10.5 }^5)
      end
    end
    connection.should have_last_search_including(:bf, '10.5^5')
  end

  it "should handle boost function with time literal" do
    session.search Post do
      keywords('pizza') do
        boost(function { Time.parse('2010-03-25 14:13:00 EDT') })
      end
    end
    connection.should have_last_search_including(:bf, '2010-03-25T18:13:00Z')
  end
 
  it "should handle arbitrary functions in a function query block" do
    session.search Post do
      keywords('pizza') do
        boost(function { product(:average_rating, 10) })
      end
    end
    connection.should have_last_search_including(:bf, 'product(average_rating_ft,10)')
  end

  it "should handle the sub function in a function query block" do
    session.search Post do
      keywords('pizza') do
        boost(function { sub(:average_rating, 10) })
      end
    end
    connection.should have_last_search_including(:bf, 'sub(average_rating_ft,10)')
  end

  it "should handle boost amounts on function query block" do
    session.search Post do
      keywords('pizza') do
        boost(function { sub(:average_rating, 10)^5 })
      end
    end
    connection.should have_last_search_including(:bf, 'sub(average_rating_ft,10)^5')
  end
 
  it "should handle nested functions in a function query block" do
    session.search Post do
      keywords('pizza') do
        boost(function { product(:average_rating, sum(:average_rating, 20)) })
      end
    end
    connection.should have_last_search_including(:bf, 'product(average_rating_ft,sum(average_rating_ft,20))')
  end

  # TODO SOLR 1.5
  it "should raise ArgumentError if string literal passed" do
    lambda do
      session.search Post do
        keywords('pizza') do
          boost(function { "hello world" })
        end
      end
    end.should raise_error(ArgumentError)
  end

  it "should raise UnrecognizedFieldError if bogus field name passed" do
    lambda do
      session.search Post do
        keywords('pizza') do
          boost(function { :bogus })
        end
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end
end

