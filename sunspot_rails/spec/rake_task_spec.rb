require 'spec_helper'
require 'rake'

describe 'sunspot namespace rake task' do
  before :all do
    require "#{Rails.root}/../../lib/sunspot/rails/tasks"
    Rake::Task.define_task(:environment)
  end

  describe 'sunspot:reindex' do
    let :run_rake_task do
      task = Rake::Task["sunspot:reindex"]
      task.reenable
      task.invoke(nil, nil, true) # Invoke but skip the reindex warning
    end

    it "should load all searchable models" do
      run_rake_task

      Sunspot.searchable.collect(&:name).should include('RakeTaskAutoLoadTestModel')
    end
  end
end
