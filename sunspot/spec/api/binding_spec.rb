require File.expand_path('spec_helper', File.dirname(__FILE__))

describe "DSL bindings" do
  it 'should give access to calling context\'s methods in search DSL' do
    value = nil
    session.search(Post) do
      value = test_method
    end
    value.should == 'value'
  end

  it 'should give access to calling context\'s id method in search DSL' do
    value = nil
    session.search(Post) do
      value = id
    end
    value.should == 16
  end

  it 'should give access to calling context\'s methods in nested DSL block' do
    value = nil
    session.search(Post) do
      any_of do
        value = test_method
      end
    end
    value.should == 'value'
  end

  it 'should give access to calling context\'s methods in double-nested DSL block' do
    value = nil
    session.search(Post) do
      any_of do
        all_of do
          value = test_method
        end
      end
    end
  end

  private

  def test_method
    'value'
  end

  def id
    16
  end
end
