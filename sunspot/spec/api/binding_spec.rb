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

  it 'should build function queries whose names the calling context also defines' do
    # Like a model class method calling solr_search, where the model responds
    # to ActiveRecord's #sum.
    searcher = Class.new do
      def search(session)
        session.search(Post) do
          keywords('pizza') do
            boost(function { sum(:average_rating, 10) })
          end
        end
      end

      def sum(*)
        'from context'
      end
    end.new

    searcher.search(session)
    expect(connection).to have_last_search_including(:bf, 'sum(average_rating_ft,10)')
  end

  it 'should define typed fields whose names the calling context also defines' do
    stub_const('BindingSpecDocument', Class.new)
    # The example group responds to rspec-mocks' #double.
    Sunspot::Setup.setup(BindingSpecDocument) { double :rating }
    expect(Sunspot::Setup.for(BindingSpecDocument).field(:rating).type).to be_a(Sunspot::Type::DoubleType)
  end

  it 'should prefer the record\'s method_missing in index-time blocks' do
    record_class = Class.new do
      def method_missing(name, *args, &block)
        name == :name ? 'from record' : super
      end
      # respond_to_missing? is deliberately not defined.
    end
    # Inside a searchable block the calling context is the model class, which
    # responds to Class#name.
    extractor = record_class.instance_eval do
      Sunspot::DataExtractor::BlockExtractor.new { name }
    end

    expect(extractor.value_for(record_class.new)).to eq('from record')
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
    test_thread = Thread.current
    tracer = TracePoint.new(:raise) do |tp|
      raised += 1 if Thread.current == test_thread && tp.raised_exception.is_a?(NoMethodError)
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

  it 'prefers a receiver method_missing over a context method of the same name' do
    receiver = Class.new do
      def method_missing(name, *args, &block)
        name == :shared_method ? 'from receiver' : super
      end
      # respond_to_missing? is deliberately not defined.
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

  it 'dispatches to a BasicObject receiver that does not implement respond_to?' do
    receiver = Class.new(BasicObject) do
      def method_missing(name, *args, &block)
        name == :proxied_method ? 'from proxy' : super
      end
    end.new

    context = Class.new do
      def resolve(receiver)
        Sunspot::Util::ContextBoundDelegate
          .instance_eval_with_context(receiver) { proxied_method }
      end
    end.new

    expect(context.resolve(receiver)).to eq('from proxy')
  end
end
