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
      post :average_rating => 2.23
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

    it 'should correctly index a virtual field' do
      post :title => 'The Blog Post'
      connection.should_receive(:add).with(hash_including(:sort_title_s => 'blog post'))
      session.index post
    end

    it 'should correctly index a field that is defined on a superclass' do
      Sunspot.setup(BaseClass) { string :author_name }
      post :author_name => 'Mat Brown'
      connection.should_receive(:add).with(hash_including(:author_name_s => 'Mat Brown'))
      session.index post
    end

    it 'should remove an object from the index' do
      connection.should_receive(:delete).with("Post #{post.id}")
      session.remove(post)
    end

    it 'should be able to remove everything from the index' do
      connection.should_receive(:delete_by_query).with("type:[* TO *]")
      session.remove_all
    end

    it 'should be able to remove everything of a given class from the index' do
      connection.should_receive(:delete_by_query).with("type:Post")
      session.remove_all(Post)
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
    lambda { session.index(Time.now) }.should raise_error(ArgumentError)
  end

  it 'should throw an ArgumentError if single-value field tries to index multiple values' do
    lambda do
      Sunspot.setup(Post) { string :author_name }
      session.index(post(:author_name => ['Mat Brown', 'Matthew Brown']))
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
