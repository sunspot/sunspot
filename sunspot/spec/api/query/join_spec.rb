require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'join' do
  it 'should search by join' do
    session.search PhotoContainer do
      with(:caption, 'blah')
    end
    expect(connection).to have_last_search_including(
      :fq, "{!join from=photo_container_id_i to=id_i v='type:\"Photo\" AND caption_s:blah'}")
  end

  it 'should greater_than search by join' do
    session.search PhotoContainer do
      with(:photo_rating).greater_than(3)
    end
    expect(connection).to have_last_search_including(
      :fq, "{!join from=photo_container_id_i to=id_i v='type:\"Photo\" AND average_rating_ft:{3\\.0 TO *}'}")
  end
end
