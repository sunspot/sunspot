require 'spec_helper'
require 'rake'

describe 'sunspot namespace rake task' do
  before :all do
    require "#{Rails.root}/../../lib/sunspot/rails/tasks"
    Rake::Task.define_task(:environment)
  end

  describe 'sunspot:reindex' do
    it "should reindex all models if none are specified" do
      run_rake_task("sunspot:reindex", '', '', true)

      # This model should not be used by any other test and therefore should only be loaded by this test
      Sunspot.searchable.collect(&:name).should include('RakeTaskAutoLoadTestModel')
    end

    it "should accept a space delimited list of models to reindex" do
      Post.should_receive(:solr_reindex)
      Author.should_receive(:solr_reindex)
      Blog.should_not_receive(:solr_reindex)

      run_rake_task("sunspot:reindex", '', "Post Author", true)
    end

    it "should accept a plus delimited list of models to reindex" do
      Post.should_receive(:solr_reindex)
      Author.should_receive(:solr_reindex)
      Blog.should_not_receive(:solr_reindex)

      run_rake_task("sunspot:reindex", '', "Post+Author", true)
    end

    it "should raise exception when all tables of sunspot models are empty" do
      STDOUT.should_receive(:puts).with("You have no data in the database. Reindexing does nothing here.")
      empty_tables
      run_rake_task("sunspot:reindex")
    end
  end
end

def run_rake_task(task_name, *task_args)
  task = Rake::Task[task_name.to_s]
  task.reenable
  task.invoke(*task_args) # Invoke but skip the reindex warning
end
