require File.expand_path('spec_helper', File.dirname(__FILE__))

describe "DSL bindings" do
  it 'should give access to calling context\'s methods in search DSL' do
    value = nil
    session.search(Post) do
      value = test_method
    end
    expect(value).to eq('value')
  end

  it 'should give access to calling context\'s id method in search DSL' do
    value = nil
    session.search(Post) do
      value = id
    end
    expect(value).to eq(16)
  end

  it 'should give access to calling context\'s methods in nested DSL block' do
    value = nil
    session.search(Post) do
      any_of do
        value = test_method
      end
    end
    expect(value).to eq('value')
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
    expect(value).to eq('value')
  end

  it 'should give access to calling context\'s methods with keyword arguments' do
    value = nil
    session.search(Post) do
      any_of do
        value = kwargs_method(a: 10, b: 20)
      end
    end
    expect(value).to eq({ a: 10, b: 20 })
  end

  private

  def test_method
    'value'
  end

  def id
    16
  end

  def kwargs_method(a:, b:)
    { a: a, b: b }
  end
end
