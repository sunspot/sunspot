require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'indexing dynamic fields' do
  it 'indexes string data' do
    session.index(post(:custom_string => { :test => 'string' }))
    connection.should have_add_with(:"custom_string:test_ss" => 'string')
  end

  it 'indexes integer data with virtual accessor' do
    session.index(post(:category_ids => [1, 2]))
    connection.should have_add_with(:"custom_integer:1_i" => '1', :"custom_integer:2_i" => '1')
  end

  it 'indexes float data' do
    session.index(post(:custom_fl => { :test => 1.5 }))
    connection.should have_add_with(:"custom_float:test_fm" => '1.5')
  end

  it 'indexes time data' do
    session.index(post(:custom_time => { :test => Time.parse('2009-05-18 18:05:00 -0400') }))
    connection.should have_add_with(:"custom_time:test_d" => '2009-05-18T22:05:00Z')
  end

  it 'indexes boolean data' do
    session.index(post(:custom_boolean => { :test => false }))
    connection.should have_add_with(:"custom_boolean:test_b" => 'false')
  end

  it 'indexes multiple values for a field' do
    session.index(post(:custom_fl => { :test => [1.0, 2.1, 3.2] }))
    connection.should have_add_with(:"custom_float:test_fm" => %w(1.0 2.1 3.2))
  end

  it 'should throw a NoMethodError if dynamic text field defined' do
    lambda do
      Sunspot.setup(Post) do
        dynamic_text :custom_text
      end
    end.should raise_error(NoMethodError)
  end
end

