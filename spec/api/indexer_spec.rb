require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'indexer' do
  describe 'when indexing an object' do
    it 'should index id and type' do
      connection.should_receive(:add).with(hash_including(:id => "Post #{post.id}", :type => ['Post', 'BaseClass']))
      session.index post
    end

    it 'should index text' do
      post :title => 'A Title', :body => 'A Post'
      connection.should_receive(:add).with(hash_including(:title_text => 'A Title', :body_text => 'A Post'))
      session.index post
    end

    it 'should correctly index a string attribute field' do
      post :title => 'A Title'
      connection.should_receive(:add).with(hash_including(:title_s => 'A Title'))
      session.index post
    end

    it 'should correctly index an integer attribute field' do
      post :blog_id => 4
      connection.should_receive(:add).with(hash_including(:blog_id_i => '4'))
      session.index post
    end

    it 'should correctly index a float attribute field' do
      post :ratings_average => 2.23
      connection.should_receive(:add).with(hash_including(:average_rating_f => '2.23'))
      session.index post
    end

    it 'should allow indexing by a multiple-value field' do
      post :category_ids => [3, 14]
      connection.should_receive(:add).with(hash_including(:category_ids_im => ['3', '14']))
      session.index post
    end

    it 'should correctly index a time field' do
      post :published_at => Time.parse('1983-07-08 05:00:00 -0400')
      connection.should_receive(:add).with(hash_including(:published_at_d => '1983-07-08T09:00:00Z'))
      session.index post
    end

    it 'should correctly index a boolean field' do
      post :featured => true
      connection.should_receive(:add).with(hash_including(:featured_b => 'true'))
      session.index post
    end

    it 'should correctly index a false boolean field' do
      post :featured => false
      connection.should_receive(:add).with(hash_including(:featured_b => 'false'))
      session.index post
    end

    it 'should not index a nil boolean field' do
      post
      connection.should_receive(:add).with(hash_not_including(:featured_b))
      session.index post
    end

    it 'should correctly index a virtual field' do
      post :title => 'The Blog Post'
      connection.should_receive(:add).with(hash_including(:sort_title_s => 'blog post'))
      session.index post
    end

    it 'should correctly index an external virtual field' do
      post :category_ids => [1, 2, 3]
      connection.should_receive(:add).with(hash_including(:primary_category_id_i => '1'))
      session.index post
    end

    it 'should correctly index a field that is defined on a superclass' do
      Sunspot.setup(BaseClass) { string :author_name }
      post :author_name => 'Mat Brown'
      connection.should_receive(:add).with(hash_including(:author_name_s => 'Mat Brown'))
      session.index post
    end

    it 'should commit immediately after index! called' do
      post :title => 'The Blog Post'
      connection.should_receive(:add).ordered
      connection.should_receive(:commit).ordered
      session.index!(post)
    end

    it 'should remove an object from the index' do
      connection.should_receive(:delete).with("Post #{post.id}")
      session.remove(post)
    end

    it 'should remove an object from the index and immediately commit' do
      connection.should_receive(:delete).with("Post #{post.id}").ordered
      connection.should_receive(:commit).ordered
      session.remove!(post)
    end

    it 'should remove everything from the index' do
      connection.should_receive(:delete_by_query).with("type:[* TO *]")
      session.remove_all
    end

    it 'should remove everything from the index and immediately commit' do
      connection.should_receive(:delete_by_query).with("type:[* TO *]").ordered
      connection.should_receive(:commit).ordered
      session.remove_all!
    end

    it 'should be able to remove everything of a given class from the index' do
      connection.should_receive(:delete_by_query).with("type:Post")
      session.remove_all(Post)
    end
  end

  describe 'dynamic fields' do
    it 'should index string data' do
      post(:custom => { :test => 'string' })
      connection.should_receive(:add).with(hash_including(:"custom:test_s" => 'string'))
      session.index(post)
    end

    it 'should index integer data' do
      post(:custom => { :test => 1 })
      connection.should_receive(:add).with(hash_including(:"custom:test_i" => '1'))
      session.index(post)
    end

    it 'should index float data' do
      post(:custom => { :test => 1.5 })
      connection.should_receive(:add).with(hash_including(:"custom:test_f" => '1.5'))
      session.index(post)
    end

    it 'should index time data' do
      post(:custom => { :test => Time.parse('2009-05-18 18:05:00 -0400') })
      connection.should_receive(:add).with(hash_including(:"custom:test_d" => '2009-05-18T22:05:00Z'))
      session.index(post)
    end

    it 'should index boolean data' do
      post(:custom => { :test => false })
      connection.should_receive(:add).with(hash_including(:"custom:test_b" => 'false'))
      session.index(post)
    end

    it 'should index multiple values for a field' do
      post(:custom_multi => { :test => [1, 2, 3] })
      connection.should_receive(:add).with(hash_including(:"multi_custom:test_i" => %w(1 2 3)))
      session.index(post)
    end

    it 'should index virtual fields' do
      post(:category_ids => [2, 4])
      connection.should_receive(:add).with(hash_including(:"virtual_custom:2_b" => 'true', :"virtual_custom:4_b" => 'true'))
      session.index(post)
    end
  end

  it 'should throw a NoMethodError only if a nonexistent type is defined' do
    lambda { Sunspot.setup(Post) { string :author_name }}.should_not raise_error
    lambda { Sunspot.setup(Post) { bogus :journey }}.should raise_error(NoMethodError)
  end

  it 'should throw a NoMethodError if a nonexistent field argument is passed' do
    lambda { Sunspot.setup(Post) { string :author_name, :bogus => :argument }}.should raise_error(ArgumentError)
  end

  it 'should throw an ArgumentError if an attempt is made to index an object that has no configuration' do
    lambda { session.index(Time.now) }.should raise_error(Sunspot::NoSetupError)
  end

  it 'should throw an ArgumentError if single-value field tries to index multiple values' do
    lambda do
      Sunspot.setup(Post) { string :author_name }
      session.index(post(:author_name => ['Mat Brown', 'Matthew Brown']))
    end.should raise_error(ArgumentError)
  end

  it 'should throw a NoAdapterError if class without adapter is indexed' do
    lambda { session.index(User.new) }.should raise_error(Sunspot::NoAdapterError)
  end

  it 'should throw an ArgumentError if a non-word character is included in the field name' do
    lambda do
      Sunspot.setup(Post) { string :"bad name" }
    end.should raise_error(ArgumentError)
  end

  private

  def config
    Sunspot::Configuration.build
  end

  def connection
    @connection ||= mock('connection')
  end

  def session
    @session ||= Sunspot::Session.new(config, connection)
  end

  def post(attrs = {})
    @post ||= Post.new(attrs)
  end
end
