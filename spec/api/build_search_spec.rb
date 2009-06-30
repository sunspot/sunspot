require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Search' do
  it 'should search by keywords from DSL' do
    session.search Post do
      keywords 'keyword search'
    end
    connection.should have_last_search_with(:q => '(keyword search) AND (type:Post)')
  end

  it 'should search by keywords from options' do
    session.search Post, :keywords => 'keyword search'
    connection.should have_last_search_with(:q => '(keyword search) AND (type:Post)')
  end

  it 'should scope by exact match with a string from DSL' do
    session.search Post do
      with :title, 'My Pet Post'
    end
    connection.should have_last_search_with(:fq => ['title_s:My\ Pet\ Post'])
  end

  it 'should scope by exact match with a string from options' do
    session.search Post, :conditions => { :title => 'My Pet Post' }
    connection.should have_last_search_with(:fq => ['title_s:My\ Pet\ Post'])
  end

  it 'should ignore nonexistant fields in hash scope' do
    session.search Post, :conditions => { :bogus => 'Field' }
    connection.should_not have_last_search_with(:fq)
  end

  it 'should scope by exact match with time' do
    time = Time.parse('1983-07-08 05:00:00 -0400')
    session.search Post do
      with :published_at, time
    end
    connection.should have_last_search_with(:fq => ['published_at_d:1983\-07\-08T09\:00\:00Z'])
  end
  
  it 'should scope by exact match with boolean' do
    session.search Post do
      with :featured, false
    end
    connection.should have_last_search_with(:fq => ['featured_b:false'])
  end

  it 'should scope by less than match with float' do
    session.search Post do
      with(:average_rating).less_than 3.0
    end
    connection.should have_last_search_with(:fq => ['average_rating_f:[* TO 3\.0]'])
  end

  it 'should scope by greater than match with float' do
    session.search Post do
      with(:average_rating).greater_than 3.0
    end
    connection.should have_last_search_with(:fq => ['average_rating_f:[3\.0 TO *]'])
  end

  it 'should scope by between match with float' do
    session.search Post do
      with(:average_rating).between 2.0..4.0
    end
    connection.should have_last_search_with(:fq => ['average_rating_f:[2\.0 TO 4\.0]'])
  end

  it 'should scope by any match with integer using DSL' do
    session.search Post do
      with(:category_ids).any_of [2, 7, 12]
    end
    connection.should have_last_search_with(:fq => ['category_ids_im:(2 OR 7 OR 12)'])
  end

  it 'should scope by any match with integer using options' do
    session.search Post, :conditions => { :category_ids => [2, 7, 12] }
    connection.should have_last_search_with(:fq => ['category_ids_im:(2 OR 7 OR 12)'])
  end

  it 'should scope by all match with integer' do
    session.search Post do
      with(:category_ids).all_of [2, 7, 12]
    end
    connection.should have_last_search_with(:fq => ['category_ids_im:(2 AND 7 AND 12)'])
  end

  it 'should scope by not equal match with string' do
    session.search Post do
      without :title, 'Bad Post'
    end
    connection.should have_last_search_with(:fq => ['-title_s:Bad\ Post'])
  end

  it 'should scope by not less than match with float' do
    session.search Post do
      without(:average_rating).less_than 3.0
    end
    connection.should have_last_search_with(:fq => ['-average_rating_f:[* TO 3\.0]'])
  end

  it 'should scope by not greater than match with float' do
    session.search Post do
      without(:average_rating).greater_than 3.0
    end
    connection.should have_last_search_with(:fq => ['-average_rating_f:[3\.0 TO *]'])
  end

  it 'should scope by not between match with float' do
    session.search Post do
      without(:average_rating).between 2.0..4.0
    end
    connection.should have_last_search_with(:fq => ['-average_rating_f:[2\.0 TO 4\.0]'])
  end

  it 'should scope by not any match with integer' do
    session.search Post do
      without(:category_ids).any_of [2, 7, 12]
    end
    connection.should have_last_search_with(:fq => ['-category_ids_im:(2 OR 7 OR 12)'])
  end


  it 'should scope by not all match with integer' do
    session.search Post do
      without(:category_ids).all_of [2, 7, 12]
    end
    connection.should have_last_search_with(:fq => ['-category_ids_im:(2 AND 7 AND 12)'])
  end

  it 'should scope by empty field' do
    session.search Post do
      with :average_rating, nil
    end
    connection.should have_last_search_with(:fq => ['-average_rating_f:[* TO *]'])
  end

  it 'should scope by non-empty field' do
    session.search Post do
      without :average_rating, nil
    end
    connection.should have_last_search_with(:fq => ['average_rating_f:[* TO *]'])
  end

  it 'should exclude by object identity' do
    post = Post.new
    session.search Post do
      without post
    end
    connection.should have_last_search_with(:fq => ["-id:Post\\ #{post.id}"])
  end

  it 'should exclude multiple objects passed as varargs by object identity' do
    post1, post2 = Post.new, Post.new
    session.search Post do
      without post1, post2
    end
    connection.should have_last_search_with(:fq => ["-id:Post\\ #{post1.id}", "-id:Post\\ #{post2.id}"])
  end

  it 'should exclude multiple objects passed as array by object identity' do
    posts = [Post.new, Post.new]
    session.search Post do
      without posts
    end
    connection.should have_last_search_with(:fq => ["-id:Post\\ #{posts.first.id}", "-id:Post\\ #{posts.last.id}"])
  end

  it 'should restrict by dynamic string field with equality restriction' do
    session.search Post do
      dynamic :custom_string do
        with :test, 'string'
      end
    end
    connection.should have_last_search_with(:fq => ['custom_string\:test_s:string'])
  end

  it 'should restrict by dynamic integer field with less than restriction' do
    session.search Post do
      dynamic :custom_integer do
        with(:test).less_than(1)
      end
    end
    connection.should have_last_search_with(:fq => ['custom_integer\:test_i:[* TO 1]'])
  end

  it 'should restrict by dynamic float field with between restriction' do
    session.search Post do
      dynamic :custom_float do
        with(:test).between(2.2..3.3)
      end
    end
    connection.should have_last_search_with(:fq => ['custom_float\:test_fm:[2\.2 TO 3\.3]'])
  end

  it 'should restrict by dynamic time field with any of restriction' do
    session.search Post do
      dynamic :custom_time do
        with(:test).any_of([Time.parse('2009-02-10 14:00:00 UTC'),
                            Time.parse('2009-02-13 18:00:00 UTC')])
      end
    end
    connection.should have_last_search_with(:fq => ['custom_time\:test_d:(2009\-02\-10T14\:00\:00Z OR 2009\-02\-13T18\:00\:00Z)'])
  end

  it 'should restrict by dynamic boolean field with equality restriction' do
    session.search Post do
      dynamic :custom_boolean do
        with :test, false
      end
    end
    connection.should have_last_search_with(:fq => ['custom_boolean\:test_b:false'])
  end

  it 'should negate a dynamic field restriction' do
    session.search Post do
      dynamic :custom_string do
        without :test, 'foo'
      end
    end
    connection.should have_last_search_with(:fq => ['-custom_string\:test_s:foo'])
  end

  it 'should throw an UnrecognizedFieldError if an unknown dynamic field is searched by' do
    lambda do
      session.search Post do
        dynamic(:bogus) { with :some, 'value' }
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should throw a NoMethodError if pagination is attempted in a dynamic query' do
    lambda do
      session.search Post do
        dynamic :custom_string do
          paginate 3, 10
        end
      end
    end.should raise_error(NoMethodError)
  end

  it 'should paginate using default per_page when page not provided' do
    session.search Post
    connection.should have_last_search_with(:rows => 30)
  end

  it 'should paginate using default per_page when page provided in DSL' do
    session.search Post do
      paginate :page => 2
    end
    connection.should have_last_search_with(:rows => 30, :start => 30)
  end

  it 'should paginate using default per_page when page provided in options' do
    session.search Post, :page => 2
    connection.should have_last_search_with(:rows => 30, :start => 30)
  end

  it 'should paginate using provided per_page in DSL' do
    session.search Post do
      paginate :page => 4, :per_page => 15
    end
    connection.should have_last_search_with(:rows => 15, :start => 45)
  end

  it 'should paginate using provided per_page in options' do
    session.search Post, :page => 4, :per_page => 15
    connection.should have_last_search_with(:rows => 15, :start => 45)
  end

  it 'should order in DSL' do
    session.search Post do
      order_by :average_rating, :desc
    end
    connection.should have_last_search_with(:sort => 'average_rating_f desc')
  end

  it 'should order in keywords' do
    session.search Post, :order => 'average_rating desc'
    connection.should have_last_search_with(:sort => 'average_rating_f desc')
  end

  it 'should order by multiple fields in DSL' do
    session.search Post do
      order_by :average_rating, :desc
      order_by :sort_title, :asc
    end
    connection.should have_last_search_with(:sort => 'average_rating_f desc, sort_title_s asc')
  end

  it 'should order by multiple fields in options' do
    session.search Post, :order => ['average_rating desc', 'sort_title asc']
    connection.should have_last_search_with(:sort => 'average_rating_f desc, sort_title_s asc')
  end

  it 'should order by a dynamic field' do
    session.search Post do
      dynamic :custom_integer do
        order_by :test, :desc
      end
    end
    connection.should have_last_search_with(:sort => 'custom_integer:test_i desc')
  end

  it 'should order by a dynamic field and static field, with given precedence' do
    session.search Post do
      dynamic :custom_integer do
        order_by :test, :desc
      end
      order_by :sort_title, :asc
    end
    connection.should have_last_search_with(:sort => 'custom_integer:test_i desc, sort_title_s asc')
  end

  it 'should throw an ArgumentError if a bogus order direction is given' do
    lambda do
      session.search Post do
        order_by :sort_title, :sideways
      end
    end.should raise_error(ArgumentError)
  end

  it 'should not turn faceting on if no facet requested' do
    session.search(Post)
    connection.should_not have_last_search_with('facet')
  end

  it 'should turn faceting on if facet is requested' do
    session.search Post do
      facet :category_ids
    end
    connection.should have_last_search_with('facet' => 'true')
  end

  it 'should request single field facet' do
    session.search Post do
      facet :category_ids
    end
    connection.should have_last_search_with(:"facet.field" => %w(category_ids_im))
  end

  it 'should request multiple field facets' do
    session.search Post do
      facet :category_ids, :blog_id
    end
    connection.should have_last_search_with(:"facet.field" => %w(category_ids_im blog_id_i))
  end

  it 'should set facet sort by count' do
    session.search Post do
      facet :category_ids, :sort => :count
    end
    connection.should have_last_search_with(:"f.category_ids_im.sort" => 'true')
  end

  it 'should set facet sort by index' do
    session.search Post do
      facet :category_ids, :sort => :index
    end
    connection.should have_last_search_with(:"f.category_ids_im.sort" => 'false')
  end

  it 'should throw ArgumentError if bogus facet sort provided' do
    lambda do
      session.search Post do
        facet :category_ids, :sort => :sideways
      end
    end.should raise_error(ArgumentError)
  end

  it 'should set the facet limit' do
    session.search Post do
      facet :category_ids, :limit => 10
    end
    connection.should have_last_search_with(:"f.category_ids_im.limit" => 10)
  end

  it 'should set the facet minimum count' do
    session.search Post do
      facet :category_ids, :minimum_count => 5
    end
    connection.should have_last_search_with(:"f.category_ids_im.mincount" => 5)
  end

  it 'should set the facet minimum count to zero if zeros are allowed' do
    session.search Post do
      facet :category_ids, :zeros => true
    end
    connection.should have_last_search_with(:"f.category_ids_im.mincount" => 0)
  end

  it 'should set the facet minimum count to one by default' do
    session.search Post do
      facet :category_ids
    end
    connection.should have_last_search_with(:"f.category_ids_im.mincount" => 1)
  end

  it 'should allow faceting by dynamic string field' do
    session.search Post do
      dynamic :custom_string do
        facet :test
      end
    end
    connection.should have_last_search_with(:"facet.field" => %w(custom_string:test_s))
  end

  it 'should build search for multiple types' do
    session.search(Post, Comment)
    connection.should have_last_search_with(:q => '(type:(Post OR Comment))')
  end

  it 'should allow search on fields common to all types with DSL' do
    time = Time.parse('1983-07-08 05:00:00 -0400')
    session.search Post, Comment do
      with :published_at, time
    end
    connection.should have_last_search_with(:fq => ['published_at_d:1983\-07\-08T09\:00\:00Z'])
  end

  it 'should allow search on fields common to all types with conditions' do
    time = Time.parse('1983-07-08 05:00:00 -0400')
    session.search Post, Comment, :conditions => { :published_at => time }
    connection.should have_last_search_with(:fq => ['published_at_d:1983\-07\-08T09\:00\:00Z'])
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
    session.search Post, Comment, :conditions => { :blog_id => 1 }
    connection.should_not have_last_search_with(:fq)
  end

  it 'should allow building search using block argument rather than instance_eval' do
    @blog_id = 1
    session.search Post do |query|
      query.with(:blog_id, @blog_id)
    end
    connection.should have_last_search_with(:fq => ['blog_id_i:1'])
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
    @connection ||= Mock::Connection.new
  end

  def session
    @session ||= Sunspot::Session.new(config, connection)
  end
end
