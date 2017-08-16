require File.expand_path('spec_helper', File.dirname(__FILE__))

shared_examples_for 'spellcheck query' do

  it 'sends spellcheck parameters to solr' do
    search do
      spellcheck
    end
    expect(connection).to have_last_search_including(:spellcheck, true)
  end


  it "sends additional spellcheck parameters with camel casing" do
    search do
      spellcheck :only_more_popular => true, :count => 5
    end
    expect(connection).to have_last_search_including('spellcheck.onlyMorePopular', true)
    expect(connection).to have_last_search_including('spellcheck.count', 5)
  end
end
