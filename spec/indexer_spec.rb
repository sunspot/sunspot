require File.join(File.dirname(__FILE__), 'spec_helper')

describe Sunspot::Indexer do
  before :each do
    Solr::Connection.stub!(:new).and_return connection
  end

  describe 'when indexing an object' do
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

    it 'should correctly index a virtual field' do
      post :title => 'The Blog Post'
      Post.is_searchable do
      end
      connection.should_receive(:add).with do |hash|
        hash[:sort_title_s].should == 'blog post'
      end
    end

    it 'should correctly index a field that is defined on a superclass' do
      BaseClass.is_searchable { string :author_name }
      post :author_name => 'Mat Brown'
      connection.should_receive(:add).with do |hash|
        hash[:author_name_s].should == 'Mat Brown'
      end
    end
  end

  it 'should throw a NoMethodError only if a nonexistent type is defined' do
    lambda { Post.configure_search { string :author_name }}.should_not raise_error
    lambda { Post.configure_search { bogus :journey }}.should raise_error(NoMethodError)
  end

  it 'should throw an ArgumentError if an attempt is made to index an object that has no configuration' do
    lambda { Sunspot::Indexer.add(Time.now) }.should raise_error(ArgumentError)
  end

  private

  def connection
    @connection ||= mock('Connection')
  end

  def post(attrs = {})
    @post ||= Post.new(attrs)
  end
end
