require File.join(File.dirname(__FILE__), 'test_helper')

class TestIntegration < Test::Unit::TestCase
  before do
    session.remove_all
    post! :sarkozy, :title => 'Nicolas Sarkozy runs around',
                    :body => '...with Carla Bruni',
                    :blog_id => 1,
                    :average_rating => 3.5
    post! :bloomberg, :title => 'Bloomberg runs for mayor again',
                      :blog_id => 2,
                      :average_rating => 2.2
    post! :gordon_brown, :title => 'Gordon Brown bores crowd',
                         :blog_id => 1,
                         :average_rating => 1.9
  end

  test 'should return items with keywords in title' do
    session.search(Post, :keywords => 'sarkozy').results.should include(post(:sarkozy))
  end

  test 'should return items with keywords in body' do
    session.search(Post, :keywords => 'bruni').results.should include(post(:sarkozy))
  end

  test 'should return items with keywords in multiple fields' do
    session.search(Post, :keywords => 'with runs').results.should include(post(:sarkozy))
  end
 
  test 'should not return items with keywords not in title or body' do
    session.search(Post, :keywords => 'gordon brown').results.should_not include(post(:sarkozy))
  end

  test 'should scope by equality to integer field' do
    results = session.search(Post) { with.blog_id 1 }.results
    results.should include(post(:sarkozy))
    results.should_not include(post(:bloomberg))
  end

  test 'should scope by greater than float field' do
    results = session.search(Post) { with.average_rating.greater_than 3 }.results
    results.should include(post(:sarkozy))
    results.should_not include(post(:bloomberg))
  end

  test 'should scope by less than float field' do
    results = session.search(Post) { with.average_rating.less_than 3 }.results
    results.should_not include(post(:sarkozy))
    results.should include(post(:bloomberg))
  end

  test 'should scope by between float field' do
    results = session.search(Post) { with.average_rating.between 2..3 }.results
    results.should include(post(:bloomberg))
    results.should_not include(post(:sarkozy))
    results.should_not include(post(:gordon_brown))
  end
  
#  test 'should order by float field ascending' do
#    results = session.search(Post) { order_by :average_rating, :asc }.results
#    debugger
#    results.index(post(:bloomberg)).should > results.index(post(:sarkozy))
#    results.index(post(:sarkozy)).should > results.index(post(:gordon_brown))
#  end

  private

  def post(name)
    @posts[name.to_s]
  end

  def post!(name, attributes)
    @posts ||= {}
    @posts[name.to_s] = post = Post.new(attributes)
    session.index(post)
  end

  def session
    Sunspot::Session.new
  end
end
