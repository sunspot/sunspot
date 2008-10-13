require File.join(File.dirname(__FILE__), 'spec_helper.rb')

# Time to add your specs!
# http://rspec.info/
describe Sunspot::Index do
  before :each do
    Solr::Connection.stub!(:new).and_return connection

    Post.is_searchable do
      # keywords :title, :body
      string :title
      integer :blog_id
      # integer :category_ids
      # time :published_at
    end
  end

  after :each do
    Sunspot::Index.add post
  end

  it 'should index id and type' do
    connection.should_receive(:add).with do |hash|
      hash[:id].should == "Post:#{post.id}"
      hash[:type].should include('Post', 'BaseClass')
    end
  end

  it 'should allow indexing by a string attribute field' do 
    post :title => 'A Title'
    connection.should_receive(:add).with do |hash|
      hash[:title_s].should == 'A Title'
    end
  end

  it 'should allow indexing by an integer attribute field' do
    post :blog_id => 4
    connection.should_receive(:add).with do |hash|
      hash[:blog_id_i].should == '4'
    end
  end

  private

  def connection
    @connection ||= mock('Connection')
  end

  def post(attrs = {})
    @post ||= Post.new(attrs)
  end
end
