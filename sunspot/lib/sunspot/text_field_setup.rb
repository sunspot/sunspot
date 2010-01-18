module Sunspot
  # 
  # A TextFieldSetup encapsulates a regular (or composite) setup, and exposes
  # the #field() method returning text fields instead of attribute fields.
  #
  class TextFieldSetup #:nodoc:
    def initialize(setup)
      @setup = setup
    end

    # 
    # Return a text field with the given name. Duck-type compatible with
    # Setup and CompositeSetup, but return text fields instead.
    #
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
