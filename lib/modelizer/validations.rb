module Modelizer
  module Validations
    def test_validations_for attribute, *validations
      @klass ||= ::Modelizer.model_class_for self
      @model ||= ::Modelizer.method_name_for @klass

      unless instance_methods.collect { |m| m.to_s }.include? "new_#{@model}"
        raise "no model template for #{@klass.name}"
      end

      # FIX: location in original test file

      validations.each do |v|
        test = send "validation_lambda_for_#{v}", @klass, @model, attribute
        define_method "test_#{attribute}_#{v}", &test
      end
    end

    private

    def validation_lambda_for_presence klass, model, attribute
      lambda do
        assert_invalid attribute, send("new_#{model}", attribute => nil)
      end
    end

    def validation_lambda_for_uniqueness klass, model, attribute
      lambda do
        existing = klass.first
        assert existing, "There's at least one #{model} fixture."

        assert_invalid attribute,
          send("new_#{model}", attribute => existing.send(attribute))
      end
    end
  end
end
