shared_examples_for 'not indexed after save' do
  it 'should not be indexed after save' do
    subject.save!
    Sunspot.commit

    subject.class.search.results.should_not include(subject)
  end
end
