module Sunspot
  module SessionProxy
    class AbstractSessionProxy #:nodoc:
      class <<self
        def delegate(*args)
          options = Util.extract_options_from(args)
          delegate = options[:to]
          args.each do |method|
            module_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              def #{method}(*args, &block)
                #{delegate}.#{method}(*args, &block)
              end
            RUBY
          end
        end

        def not_supported(*methods)
          methods.each do |method|
            module_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              def #{method}(*args, &block)
                raise NotSupportedError, "#{name} does not support #{method.inspect}"
              end
            RUBY
          end
        end
      end
    end
  end
end
