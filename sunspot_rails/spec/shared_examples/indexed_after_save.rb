shared_examples_for 'indexed after save' do
  it 'should be indexed after save' do
    subject.save!
    Sunspot.commit

    subject.class.search.results.should include(subject)
  end
end
