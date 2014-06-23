require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'search with spellcheck results', :type => :search do  

  it 'should have spellcheck in results' do
    stub_spellcheck
    result = session.search Post do 
      spellcheck 
    end
    result.suggestions.keys.include?("wrng").should == true
    result.suggestions.keys.include?("spellng").should == true
  end
  
  it 'should have build a collation suggestion' do
    stub_spellcheck
    session.search(Post){spellcheck}.collation.should == "wrong spelling"
  end
  
  it 'should have correctlySpelled boolean' do
    stub_spellcheck
    session.search(Post){spellcheck}.suggestions['correctlySpelled'].should == false
  end

end