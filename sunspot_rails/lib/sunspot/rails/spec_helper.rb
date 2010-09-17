module Sunspot
  module Rails
    module SpecHelper
      def disconnect_sunspot
        before(:each) do
          Sunspot.session = StubSessionProxy.new(Sunspot.session)
        end

        after(:each) do
          Sunspot.session = Sunspot.session.original_session
        end
      end
    end
  end
end

rspec =
  begin
    RSpec
  rescue NameError, ArgumentError
    Spec::Runner
  end

rspec.configure do |config|
  config.extend(Sunspot::Rails::SpecHelper)
end
