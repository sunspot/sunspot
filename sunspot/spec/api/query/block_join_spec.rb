require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'block join queries' do
  it 'test' do
    Sunspot.search(Parent) do
      require 'byebug'
      byebug
      child_of -> { with :name, 'Hello!' } do
        with :name, 'Hello!'
      end
    end
  end
end