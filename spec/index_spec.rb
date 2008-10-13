require File.join(File.dirname(__FILE__), 'spec_helper.rb')

# Time to add your specs!
# http://rspec.info/
describe Sunspot::Index do
  before :each do
    Solr::Connection.should_receive(:new).and_return connection

    Post.is_searchable do
      # keywords :title, :body
      string :title
      # integer :blog_id
      # integer :category_ids
      # time :published_at
    end
  end

  it 'should allow indexing by a string attribute field' do 
    post = Post.new :title => 'A Title'
    connection.should_receive(:add).with do |hash|
      hash[:title_s].should == 'A Title'
    end
    Sunspot::Index.add post
  end

  private

  def connection
    @connection ||= stub('Connection')
  end
end
