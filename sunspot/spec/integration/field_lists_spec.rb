require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'fields lists' do
  before :all do
    Sunspot.remove_all
    @post = Post.new(title: 'A Title', body: 'A Body', featured: true, tags: ['tag'])
    Sunspot.index!(@post)
  end

  let(:stored_field_names) do
    (Sunspot::Setup.for(Post).fields + Sunspot::Setup.for(Post).all_text_fields)
      .select { |f| f.stored? }
      .map { |f| f.name }
  end

  it 'loads all stored fields by dafault' do
    hit = Sunspot.search(Post).hits.first

    stored_field_names.each do |field|
      expect(hit.stored(field)).not_to be_nil
    end
  end

  it 'loads only filtered fields' do
    hit = Sunspot.search(Post) { field_list(:title) }.hits.first

    expect(hit.stored(:title)).to eq(@post.title)

    (stored_field_names - [:title]).each do |field|
      expect(hit.stored(field)).to be_nil
    end
  end

  it 'does not raise Sunspot::UnrecognizedFieldError when listing existing text fields' do
    expect do
      Sunspot.search(Post) {
        field_list(:body)
      }
    end.to_not raise_error
  end

  it 'does raise Sunspot::UnrecognizedFieldError when listing a non-existent text fields' do
    expect do
      Sunspot.search(Post) {
        field_list(:bogus_body)
      }
    end.to raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'does not load any stored fields' do
    hit = Sunspot.search(Post) { without_stored_fields }.hits.first

    stored_field_names.each do |field|
      expect(hit.stored(field)).to be_nil
    end
  end
end
