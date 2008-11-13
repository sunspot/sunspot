module Matchy
  module Expectations
    class RespondToExpectation < Base
      def matches?(receiver)
        @receiver = receiver
        receiver.respond_to?(@expected)
      end

      def failure_message
        "Expected #{@receiver.inspect} to respond to #{@expected.inspect}"
      end

      def negative_failure_message
        "Expected #{@receiver.inspect} to not respond to #{@expected.inspect}"
      end
    end

    module TestCaseExtensions
      def respond_to(method)
        Matchy::Expectations::RespondToExpectation.new(method, self)
      end
    end
  end
end
