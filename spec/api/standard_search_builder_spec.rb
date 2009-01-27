require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'standard search builder' do
  before :each do
    stub_results
  end

  it 'should give access to order through hash and object' do
    search = session.search(Post, :order => 'sort_title asc')
    search.builder.params[:order].should == 'sort_title asc'
    search.builder.order.should == 'sort_title asc'
  end

  it 'should give nil order if no order set' do
    search = session.search(Post)
    search.builder.params.should have_key(:order)
    search.builder.params[:order].should be_nil
    search.builder.order.should be_nil
  end

  it 'should give access to page and per-page through hash and object' do
    search = session.search(Post, :page => 2, :per_page => 15)
    search.builder.params[:page].should == 2
    search.builder.params[:per_page].should == 15
    search.builder.page.should == 2
    search.builder.per_page.should == 15
  end

  it 'should give access to keywords' do
    search = session.search(Post, :keywords => 'some keywords')
    search.builder.params[:keywords].should == 'some keywords'
    search.builder.keywords.should == 'some keywords'
  end

  it 'should have nil keywords if no keywords given' do
    search = session.search(Post)
    search.builder.params.should have_key(:keywords)
    search.builder.params[:keywords].should be_nil
    search.builder.keywords.should be_nil
  end

  it 'should give access to conditions' do
    search = session.search(Post, :conditions => { :blog_id => 1 })
    search.builder.params[:conditions][:blog_id].should == 1
    search.builder.conditions.blog_id.should == 1
  end

  it 'should have nil values for fields with unspecified conditions' do
    search = session.search(Post)
    %w(title blog_id category_ids average_rating published_at sort_title).each do |field_name|
      search.builder.params[:conditions].should have_key(field_name.to_sym)
      search.builder.params[:conditions][field_name.to_sym].should == nil
      search.builder.conditions.should respond_to(field_name)
      search.builder.conditions.send(field_name).should == nil
    end
  end

  private

  def stub_results(*results)
    response = mock('response', :hits => [], :total_hits => 0)
    connection.stub!(:query).and_return(response)
  end

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
