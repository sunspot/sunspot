shared_examples_for 'indexed after save' do
  it 'should be indexed after save' do
    subject.save!
    Sunspot.commit

    expect(subject.class.search.results).to include(subject)
  end
end
