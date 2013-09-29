require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'join' do
  it 'should search by join' do
    session.search PhotoContainer do
      with(:caption).from_join('photo', 'blah')
    end
    connection.should have_last_search_including(
      :fq, "{!join from=photo_container_id to=id}caption_s:blah")
  end
end