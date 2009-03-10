require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Search' do
  it 'should search by keywords' do
    connection.should_receive(:query).with('(keyword search) AND (type:Post)', hash_including).twice
    session.search Post, :keywords => 'keyword search'
    session.search Post do
      keywords 'keyword search'
    end
  end

  it 'should scope by exact match with a string' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['title_s:My\ Pet\ Post'])).twice
    session.search Post, :conditions => { :title => 'My Pet Post' }
    session.search Post do
      with.title 'My Pet Post'
    end
  end

  it 'should ignore nonexistant fields in hash scope' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => []))
    session.search Post, :conditions => { :bogus => 'Field' }
  end

  it 'should raise an ArgumentError for nonexistant fields in block scope' do
    lambda do 
      session.search Post do
        with.bogus 'Field'
      end
    end.should raise_error(ArgumentError)
  end

  it 'should scope by exact match with time' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['published_at_d:1983\-07\-08T09\:00\:00Z'])).twice
    time = Time.parse('1983-07-08 05:00:00 -0400')
    session.search Post, :conditions => { :published_at => time }
    session.search Post do
      with.published_at time
    end
  end

  it 'should scope by less than match with float' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['average_rating_f:[* TO 3\.0]']))
    session.search Post do
      with.average_rating.less_than 3.0
    end
  end

  it 'should scope by greater than match with float' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['average_rating_f:[3\.0 TO *]']))
    session.search Post do
      with.average_rating.greater_than 3.0
    end
  end

  it 'should scope by between match with float' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['average_rating_f:[2\.0 TO 4\.0]']))
    session.search Post do
      with.average_rating.between 2.0..4.0
    end
  end

  it 'should scope by any match with integer' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['category_ids_im:(2 OR 7 OR 12)'])).twice
    session.search Post, :conditions => { :category_ids => [2, 7, 12] }
    session.search Post do
      with.category_ids.any_of [2, 7, 12]
    end
  end

  it 'should scope by all match with integer' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['category_ids_im:(2 AND 7 AND 12)']))
    session.search Post do
      with.category_ids.all_of [2, 7, 12]
    end
  end

  it 'should scope by not equal match with string' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-title_s:Bad\ Post']))
    session.search Post do
      without.title 'Bad Post'
    end
  end

  it 'should scope by not less than match with float' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-average_rating_f:[* TO 3\.0]']))
    session.search Post do
      without.average_rating.less_than 3.0
    end
  end

  it 'should scope by not greater than match with float' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-average_rating_f:[3\.0 TO *]']))
    session.search Post do
      without.average_rating.greater_than 3.0
    end
  end

  it 'should scope by not between match with float' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-average_rating_f:[2\.0 TO 4\.0]']))
    session.search Post do
      without.average_rating.between 2.0..4.0
    end
  end

  it 'should scope by not any match with integer' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-category_ids_im:(2 OR 7 OR 12)']))
    session.search Post do
      without.category_ids.any_of [2, 7, 12]
    end
  end


  it 'should scope by not all match with integer' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-category_ids_im:(2 AND 7 AND 12)']))
    session.search Post do
      without.category_ids.all_of [2, 7, 12]
    end
  end

  it 'should paginate using default per_page when page not provided' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:rows => 30))
    session.search Post
  end

  it 'should paginate using default per_page when page provided' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:rows => 30, :start => 30)).twice
    session.search Post, :page => 2
    session.search Post do
      paginate :page => 2
    end
  end

  it 'should paginate using provided per_page' do
    connection.should_receive(:query).with('(type:Post)', :filter_queries => [], :rows => 15, :start => 45).twice
    session.search Post, :page => 4, :per_page => 15
    session.search Post do
      paginate :page => 4, :per_page => 15
    end
  end

  it 'should order' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:sort => [{ :average_rating_f => :descending }])).twice
    session.search Post, :order => 'average_rating desc'
    session.search Post do
      order_by :average_rating, :desc
    end
  end

  it 'should build search for multiple types' do
    connection.should_receive(:query).with('(type:(Post OR Comment))', hash_including)
    session.search(Post, Comment)
  end

  it 'should allow search on fields common to all types' do
    connection.should_receive(:query).with('(type:(Post OR Comment))', hash_including(:filter_queries => ['published_at_d:1983\-07\-08T09\:00\:00Z'])).twice
    time = Time.parse('1983-07-08 05:00:00 -0400')
    session.search Post, Comment, :conditions => { :published_at => time }
    session.search Post, Comment do
      with.published_at time
    end
  end

  it 'should raise exception if search scoped to field not common to all types' do
    lambda do
      session.search Post, Comment do
        with.blog_id 1
      end
    end.should raise_error(ArgumentError)
  end

  it 'should raise exception if search scoped to field configured differently between types' do
    lambda do
      session.search Post, Comment do
        with.average_rating 2.2 # this is a float in Post but an integer in Comment
      end
    end.should raise_error(ArgumentError)
  end

  it 'should ignore condition if field is not common to all types' do
    connection.should_receive(:query).with('(type:(Post OR Comment))', hash_including(:filter_queries => []))    
    session.search Post, Comment, :conditions => { :blog_id => 1 }
  end

  it 'should raise ArgumentError if bogus field scoped' do
    lambda do
      session.search Post do
        with.bogus.equal_to :field
      end
    end.should raise_error(ArgumentError)
  end

  it 'should raise NoMethodError if bogus operator referenced' do
    lambda do
      session.search Post do
        with.category_ids.resembling :bogus_condition
      end
    end.should raise_error(NoMethodError)
  end

  it 'should raise ArgumentError if no :page argument given to paginate' do
    lambda do
      session.search Post do
        paginate
      end
    end.should raise_error(ArgumentError)
  end

  it 'should raise ArgumentError if bogus argument given to paginate' do
    lambda do
      session.search Post do
        paginate :page => 4, :ugly => :puppy
      end
    end.should raise_error(ArgumentError)
  end

  it 'should raise NoMethodError if more than one argument passed to scope method' do # or should it?
    lambda do
      session.search Post do
        with.category_ids 4, 5
      end
    end.should raise_error(NoMethodError)
  end

  private

  def config
    @config ||= Sunspot::Configuration.build
  end

  def connection
    @connection ||= mock('connection')
  end

  def session
    @session ||= Sunspot::Session.new(config, connection)
  end
end
