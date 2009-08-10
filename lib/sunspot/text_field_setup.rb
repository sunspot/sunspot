module Sunspot
  class TextFieldSetup
    def initialize(setup)
      @setup = setup
    end

    def field(name)
      fields = @setup.text_fields(name)
      if fields
        if fields.length == 1
          fields.first
        else
          raise(
            Sunspot::UnrecognizedFieldError,
            "The text field with name #{name} has incompatible configurations for the classes #{@setup.type_names.join(', ')}"
          )
        end
      end
    end
  end
end
