module Modelizer
  module Assertions
    def assert_invalid attribute, model, match = nil
      assert !model.valid?,
        "#{model.class.name} should have invalid #{attribute}, but it's valid."

      errors = model.errors[attribute]
      
      assert !errors.nil? && !errors.empty?,
      "No error on #{attribute}, but: " +
        model.errors.full_messages.join(", ")

      assert_match match, model.errors.on(attribute) if match
    end
  end
end
