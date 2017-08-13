require File.expand_path('../spec_helper', File.dirname(__FILE__))

shared_examples 'dynamic fields' do
  before :each do
    Sunspot.remove_all
    @posts = Post.new(field_name => { :cuisine => 'Pizza' }),
             Post.new(field_name => { :cuisine => 'Greek' }),
             Post.new(field_name => { :cuisine => 'Greek' })
    Sunspot.index!(@posts)
  end

  it 'should search for dynamic string field' do
    expect(Sunspot.search(Post) do
      dynamic(field_name) do
        with(:cuisine, 'Pizza')
      end
    end.results).to eq([@posts.first])
  end

  describe 'faceting' do
    before :each do
      @search = Sunspot.search(Post) do
        dynamic field_name do
          facet :cuisine
        end
      end
    end

    it 'should return value "value" with count 2' do
      row = @search.dynamic_facet(field_name, :cuisine).rows[0]
      expect(row.value).to eq('Greek')
      expect(row.count).to eq(2)
    end

    it 'should return value "other" with count 1' do
      row = @search.dynamic_facet(field_name, :cuisine).rows[1]
      expect(row.value).to eq('Pizza')
      expect(row.count).to eq(1)
    end
  end

  it 'should order by dynamic string field ascending' do
    expect(Sunspot.search(Post) do
      dynamic field_name do
        order_by :cuisine, :asc
      end
    end.results.last).to eq(@posts.first)
  end

  it 'should order by dynamic string field descending' do
    expect(Sunspot.search(Post) do
      dynamic field_name do
        order_by :cuisine, :desc
      end
    end.results.first).to eq(@posts.first)
  end
end

describe "default separator" do
  it_behaves_like "dynamic fields" do
    let(:field_name) { :custom_string }
  end
end
describe "custom separator" do
  it_behaves_like "dynamic fields" do
    let(:field_name) { :custom_underscored_string }
  end
end
