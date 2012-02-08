require File.expand_path('spec_helper', File.dirname(__FILE__))
require 'resque'
describe "Sunspot rake tasks" do
  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    @rake.init
    @rake.load_rakefile
  end

  describe "sunspot:got_orphans" do
    before do
      @task_name = "sunspot:got_orphans"
      posts = Array.new(2) { Post.create }.each { |post| post.index }
      Sunspot.commit
      posts.first.destroy
    end

    it "should report models whose DB counts differ from their Solr doc counts" do
      STDOUT.should_receive(:puts).with("Post has 1 orphans in Solr.")
      @rake[@task_name].invoke
    end
  end

  describe "sunspot:reindex" do
    before do
      @task_name = "sunspot:reindex"
    end

    it "should observe parameter to enqueue reindexing the models" do
      first = Post.create!
      second = Post.create!
      third = Post.create!
      Post.should_receive(:solr_clean_index_orphans).once
      Resque.should_receive(:enqueue).with(Sunspot::Rails::ResqueReindexer, "PostWithDefaultScope", kind_of(Numeric), kind_of(Numeric)).at_least(:once)
      Resque.should_receive(:enqueue).with(Sunspot::Rails::ResqueReindexer, "PostWithAuto", kind_of(Numeric), kind_of(Numeric)).at_least(:once)
      Resque.should_receive(:enqueue).with(Sunspot::Rails::ResqueReindexer, "Post", first.id, second.id)
      Resque.should_receive(:enqueue).with(Sunspot::Rails::ResqueReindexer, "Post", third.id, third.id)
      @rake[@task_name].invoke("2", "", 'true')
    end
  end

end
