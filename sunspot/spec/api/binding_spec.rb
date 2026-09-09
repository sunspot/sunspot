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

describe Sunspot::Util::ContextBoundDelegate do
  # Resolution must not depend on raising; the discarded backtraces are costly.
  it 'does not raise NoMethodError when resolving a calling context method' do
    raised = 0
    tracer = TracePoint.new(:raise) do |tp|
      raised += 1 if tp.raised_exception.is_a?(NoMethodError)
    end

    context = Class.new do
      def resolve(receiver)
        Sunspot::Util::ContextBoundDelegate
          .instance_eval_with_context(receiver) { context_only_method }
      end

      def context_only_method
        'from context'
      end
    end.new

    result = nil
    tracer.enable { result = context.resolve(Object.new) }

    expect(result).to eq('from context')
    expect(raised).to eq(0)
  end

  # respond_to? cannot see method_missing, so this must still resolve via the
  # rescue-based fallback.
  it 'resolves a calling context method that only exists via method_missing' do
    context = Class.new do
      def resolve(receiver)
        Sunspot::Util::ContextBoundDelegate
          .instance_eval_with_context(receiver) { ghost_method }
      end

      def method_missing(name, *args, &block)
        name == :ghost_method ? 'from method_missing' : super
      end
      # respond_to_missing? is deliberately not defined.
    end.new

    expect(context.resolve(Object.new)).to eq('from method_missing')
  end

  it 'raises NoMethodError when neither the receiver nor the context responds' do
    context = Class.new do
      def resolve(receiver)
        Sunspot::Util::ContextBoundDelegate
          .instance_eval_with_context(receiver) { totally_unknown_method }
      end
    end.new

    expect { context.resolve(Object.new) }.to raise_error(NoMethodError)
  end

  it 'prefers the receiver when both define the method' do
    receiver = Class.new do
      def shared_method
        'from receiver'
      end
    end.new

    context = Class.new do
      def resolve(receiver)
        Sunspot::Util::ContextBoundDelegate
          .instance_eval_with_context(receiver) { shared_method }
      end

      def shared_method
        'from context'
      end
    end.new

    expect(context.resolve(receiver)).to eq('from receiver')
  end
end
