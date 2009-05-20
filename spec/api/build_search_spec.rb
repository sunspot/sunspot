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
      with :title, 'My Pet Post'
    end
  end

  it 'should ignore nonexistant fields in hash scope' do
    connection.should_receive(:query).with('(type:Post)', hash_not_including(:filter_queries))
    session.search Post, :conditions => { :bogus => 'Field' }
  end

  it 'should scope by exact match with time' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['published_at_d:1983\-07\-08T09\:00\:00Z'])).twice
    time = Time.parse('1983-07-08 05:00:00 -0400')
    session.search Post, :conditions => { :published_at => time }
    session.search Post do
      with :published_at, time
    end
  end
  
  it 'should scope by exact match with boolean' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['featured_b:false'])).twice
    session.search Post, :conditions => { :featured => false }
    session.search Post do
      with :featured, false
    end
  end

  it 'should scope by less than match with float' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['average_rating_f:[* TO 3\.0]']))
    session.search Post do
      with(:average_rating).less_than 3.0
    end
  end

  it 'should scope by greater than match with float' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['average_rating_f:[3\.0 TO *]']))
    session.search Post do
      with(:average_rating).greater_than 3.0
    end
  end

  it 'should scope by between match with float' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['average_rating_f:[2\.0 TO 4\.0]'])).twice
    session.search Post, :conditions => { :average_rating => 2.0..4.0 }
    session.search Post do
      with(:average_rating).between 2.0..4.0
    end
  end

  it 'should scope by any match with integer' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['category_ids_im:(2 OR 7 OR 12)'])).twice
    session.search Post, :conditions => { :category_ids => [2, 7, 12] }
    session.search Post do
      with(:category_ids).any_of [2, 7, 12]
    end
  end

  it 'should scope by all match with integer' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['category_ids_im:(2 AND 7 AND 12)']))
    session.search Post do
      with(:category_ids).all_of [2, 7, 12]
    end
  end

  it 'should scope by not equal match with string' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-title_s:Bad\ Post']))
    session.search Post do
      without :title, 'Bad Post'
    end
  end

  it 'should scope by not less than match with float' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-average_rating_f:[* TO 3\.0]']))
    session.search Post do
      without(:average_rating).less_than 3.0
    end
  end

  it 'should scope by not greater than match with float' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-average_rating_f:[3\.0 TO *]']))
    session.search Post do
      without(:average_rating).greater_than 3.0
    end
  end

  it 'should scope by not between match with float' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-average_rating_f:[2\.0 TO 4\.0]']))
    session.search Post do
      without(:average_rating).between 2.0..4.0
    end
  end

  it 'should scope by not any match with integer' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-category_ids_im:(2 OR 7 OR 12)']))
    session.search Post do
      without(:category_ids).any_of [2, 7, 12]
    end
  end


  it 'should scope by not all match with integer' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-category_ids_im:(2 AND 7 AND 12)']))
    session.search Post do
      without(:category_ids).all_of [2, 7, 12]
    end
  end

  it 'should scope by empty field' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['-average_rating_f:[* TO *]']))
    session.search Post do
      with :average_rating, nil
    end
  end

  it 'should scope by non-empty field' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['average_rating_f:[* TO *]']))
    session.search Post do
      without :average_rating, nil
    end
  end

  it 'should exclude by object identity' do
    post = Post.new
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ["-id:Post\\ #{post.id}"]))
    session.search Post do
      without post
    end
  end

  it 'should exclude multiple objects passed as varargs by object identity' do
    post1, post2 = Post.new, Post.new
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ["-id:Post\\ #{post1.id}", "-id:Post\\ #{post2.id}"]))
    session.search Post do
      without post1, post2
    end
  end

  it 'should exclude multiple objects passed as array by object identity' do
    posts = [Post.new, Post.new]
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ["-id:Post\\ #{posts.first.id}", "-id:Post\\ #{posts.last.id}"]))
    session.search Post do
      without posts
    end
  end

  it 'should restrict by dynamic string field with equality restriction' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['custom_string\:test_s:string']))
    session.search Post do
      dynamic :custom_string do
        with :test, 'string'
      end
    end
  end

  it 'should restrict by dynamic integer field with less than restriction' do
    connection.should_receive(:query).with(anything, hash_including(:filter_queries => ['custom_integer\:test_i:[* TO 1]']))
    session.search Post do
      dynamic :custom_integer do
        with(:test).less_than(1)
      end
    end
  end

  it 'should restrict by dynamic float field with between restriction' do
    connection.should_receive(:query).with(anything, hash_including(:filter_queries => ['custom_float\:test_fm:[2\.2 TO 3\.3]']))
    session.search Post do
      dynamic :custom_float do
        with(:test).between(2.2..3.3)
      end
    end
  end

  it 'should restrict by dynamic time field with any of restriction' do
    connection.should_receive(:query).with(anything, hash_including(:filter_queries => ['custom_time\:test_d:(2009\-02\-10T14\:00\:00Z OR 2009\-02\-13T18\:00\:00Z)']))
    session.search Post do
      dynamic :custom_time do
        with(:test).any_of([Time.parse('2009-02-10 14:00:00 UTC'),
                            Time.parse('2009-02-13 18:00:00 UTC')])
      end
    end
  end

  it 'should restrict by dynamic boolean field with equality restriction' do
    connection.should_receive(:query).with(anything, hash_including(:filter_queries => ['custom_boolean\:test_b:false']))
    session.search Post do
      dynamic :custom_boolean do
        with :test, false
      end
    end
  end

  it 'should negate a dynamic field restriction' do
    pending 'negation for dynamic queries'
    connection.should_receive(:query).with(anything, hash_including(:filter_queries => ['-custom_string\:test_s:foo']))
    session.search Post do
      dynamic :custom_string do
        without :test, 'foo'
      end
    end
  end

  it 'should throw an UnrecognizedFieldError if an unknown dynamic field is searched by' do
    lambda do
      session.search Post do
        dynamic(:bogus) { with :some, 'value' }
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
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
    connection.should_receive(:query).with('(type:Post)', hash_including(:rows => 15, :start => 45)).twice
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

  it 'should order by multiple fields' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:sort => [{ :average_rating_f => :descending },
                                                                                   { :sort_title_s => :ascending }])).twice
    session.search Post, :order => ['average_rating desc', 'sort_title asc']
    session.search Post do
      order_by :average_rating, :desc
      order_by :sort_title, :asc
    end
  end

  it 'should order by a dynamic field' do
    connection.should_receive(:query).with(anything, hash_including(:sort => [{ :"custom_integer:test_i" => :descending }]))
    session.search Post do
      dynamic :custom_integer do
        order_by :test, :desc
      end
    end
  end

  it 'should order by a dynamic field and static field, with given precedence' do
    connection.should_receive(:query).with(anything, hash_including(:sort => [{ :"custom_integer:test_i" => :descending },
                                                                              { :sort_title_s => :ascending}]))
    session.search Post do
      dynamic :custom_integer do
        order_by :test, :desc
      end
      order_by :sort_title, :asc
    end
  end

  it 'should request single field facet' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:facets => { :fields => %w(category_ids_im) }))
    session.search Post do
      facet :category_ids
    end
  end

  it 'should request multiple field facets' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:facets => { :fields => %w(category_ids_im blog_id_i) }))
    session.search Post do
      facet :category_ids, :blog_id
    end
  end

  it 'should allow faceting by dynamic string field' do
    connection.should_receive(:query).with(anything, hash_including(:facets => { :fields => %w(custom_string:test_s) }))
    session.search Post do
      dynamic :custom_string do
        facet :test
      end
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
      with :published_at, time
    end
  end

  it 'should raise Sunspot::UnrecognizedFieldError if search scoped to field not common to all types' do
    lambda do
      session.search Post, Comment do
        with :blog_id, 1
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should raise Sunspot::UnrecognizedFieldError if search scoped to field configured differently between types' do
    lambda do
      session.search Post, Comment do
        with :average_rating, 2.2 # this is a float in Post but an integer in Comment
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should ignore condition if field is not common to all types' do
    connection.should_receive(:query).with('(type:(Post OR Comment))', hash_not_including(:filter_queries))
    session.search Post, Comment, :conditions => { :blog_id => 1 }
  end

  it 'should allow building search using block argument rather than instance_eval' do
    connection.should_receive(:query).with('(type:Post)', hash_including(:filter_queries => ['blog_id_i:1']))
    @blog_id = 1
    session.search Post do |query|
      query.with(:blog_id, @blog_id)
    end
  end

  it 'should raise Sunspot::UnrecognizedFieldError for nonexistant fields in block scope' do
    lambda do
      session.search Post do
        with :bogus, 'Field'
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should raise NoMethodError if bogus operator referenced' do
    lambda do
      session.search Post do
        with(:category_ids).resembling :bogus_condition
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

  it 'should raise ArgumentError if more than two arguments passed to scope method' do
    lambda do
      session.search Post do
        with(:category_ids, 4, 5)
      end
    end.should raise_error(ArgumentError)
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
