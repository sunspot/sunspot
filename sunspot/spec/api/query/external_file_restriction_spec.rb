require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'external file field' do
  it 'can search by external file field with value' do
    session.search Photo do
      with(:popularity, '2')
    end
    connection.should have_last_search_including(
      :fq, "{!frange l=2.0 u=2.0}popularity_ext")
  end

  it 'can search by external file field with greater_than value' do
    session.search Photo do
      with(:popularity).greater_than('1')
    end
    connection.should have_last_search_including(
      :fq, "{!frange l=1.0 incl=false}popularity_ext")
  end

  it 'can search by external file field with less_than value' do
    session.search Photo do
      with(:popularity).less_than('5')
    end
    connection.should have_last_search_including(
      :fq, "{!frange u=5.0 incu=false}popularity_ext")
  end

  it 'can search by external file field with greater_than_or_equal_to value' do
    session.search Photo do
      with(:popularity).greater_than_or_equal_to('1')
    end
    connection.should have_last_search_including(
      :fq, "{!frange l=1.0 incl=true}popularity_ext")
  end

  it 'can search by external file field with less_than_or_equal_to value' do
    session.search Photo do
      with(:popularity).less_than_or_equal_to('5')
    end
    connection.should have_last_search_including(
      :fq, "{!frange u=5.0 incu=true}popularity_ext")
  end

  it 'can search by external file field with between value' do
    session.search Photo do
      with(:popularity, 2.0..5.0)
    end
    connection.should have_last_search_including(
      :fq, "{!frange l=2.0 u=5.0 incl=true incu=true}popularity_ext")
  end
end
