require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Sunspot::Rails session' do
  it 'should be a different object for each thread' do
    session1 = nil
    session2 = nil
    Thread.new { session1 = Sunspot::Rails.session }.join
    Thread.new { session2 = Sunspot::Rails.session }.join
    session1.should_not eql(session2)
  end
end
