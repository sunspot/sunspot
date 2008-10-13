require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe Sunspot::Indexer do
  before :each do
    Solr::Connection.stub!(:new).and_return connection

    Post.is_searchable do
      keywords :title, :body
      string :title
      integer :blog_id
      integer :category_ids
      float :average_rating
      time :published_at
    end
  end

  after :each do
    Sunspot::Indexer.add post
  end

  it 'should index id and type' do
    connection.should_receive(:add).with do |hash|
      hash[:id].should == "Post:#{post.id}"
      hash[:type].should include('Post', 'BaseClass')
    end
  end

  it 'should index keywords' do
    post :title => 'A Title', :body => 'A Post'
    connection.should_receive(:add).with do |hash|
      hash[:title_text].should == 'A Title'
      hash[:body_text].should == 'A Post'
    end
  end

  it 'should correctly index a string attribute field' do 
    post :title => 'A Title'
    connection.should_receive(:add).with do |hash|
      hash[:title_s].should == 'A Title'
    end
  end

  it 'should correctly index an integer attribute field' do
    post :blog_id => 4
    connection.should_receive(:add).with do |hash|
      hash[:blog_id_i].should == '4'
    end
  end

  it 'should correctly index a float attribute field' do
    post :average_rating => 2.23
    connection.should_receive(:add).with do |hash|
      hash[:average_rating_f].should == '2.23'
    end
  end

  it 'should allow indexing by a multiple-value field' do
    post :category_ids => [3, 14]
    connection.should_receive(:add).with do |hash|
      hash[:category_ids_i].should == ['3', '14']
    end
  end

  it 'should correctly index a time field' do
    post :published_at => Time.parse('1983-07-08 05:00:00 -0400')
    connection.should_receive(:add).with do |hash|
      hash[:published_at_t].should == '1983-07-08T09:00:00Z'
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
