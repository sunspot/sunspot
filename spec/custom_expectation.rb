module Matchy
  module Expectations
    class HaveKeyExpectation < Base
      def matches?(receiver)
        @receiver = receiver
        receiver.has_key?(@expected)
      end

      def failure_message
        "Expected #{@receiver.inspect} to have key #{@expected.inspect}"
      end

      def negative_failure_message
        "Expected #{@receiver.inspect} not to have key #{@expected.inspect}"
      end
    end

    class BooleanExpectation < Base
      def initialize(method, args, test_case)
        @method = method
        @args = args
        @test_case = test_case
      end

      def matches?(receiver)
        @receiver = receiver
        receiver.send("#{@method}?", *@args)
      end
      
      def failure_message
        "Expected #{@receiver} to #{'be ' if @args.empty?}#{@method}#{@args.map { |arg| arg.inspect } * ', '}"
      end

      def negative_failure_message
        "Expected #{@receiver} to not #{'be ' if @args.empty?}#{@method}#{@args.map { |arg| arg.inspect } * ', '}"
      end
    end

    module TestCaseExtensions
      def have_key(key)
        Matchy::Expectations::HaveKeyExpectation.new(key, self)
      end

      def method_missing(method, *args, &block)
        if match = /be_(.*)/.match(method.to_s)
          Matchy::Expectations::BooleanExpectation.new(match[1], [], self)
        else
          Matchy::Expectations::BooleanExpectation.new(method.to_s, args, self)
        end
      end
    end
  end
end
