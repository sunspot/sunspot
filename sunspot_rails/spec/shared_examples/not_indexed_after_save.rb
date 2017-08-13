shared_examples_for 'not indexed after save' do
  it 'should not be indexed after save' do
    subject.save!
    Sunspot.commit

    expect(subject.class.search.results).not_to include(subject)
  end
end
