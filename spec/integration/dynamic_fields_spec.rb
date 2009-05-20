describe 'dynamic fields' do
  before :each do
    @posts = Post.new(:custom_string => { :cuisine => 'Pizza' }),
             Post.new(:custom_string => { :cuisine => 'Greek' })
    Sunspot.index!(@posts)
  end

  it 'should search for dynamic string field' do
    Sunspot.search(Post) do
      dynamic(:custom_string) do
        with(:cuisine, 'Pizza')
      end
    end.results.should == [@posts.first]
  end
end
