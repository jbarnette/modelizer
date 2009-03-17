module Modelizer
  module Validations
    def test_validations_for attribute, *validations
      @klass ||= name.gsub(/Test$/, "").constantize
      @model ||= @klass.name.underscore.tr("/", "_")

      unless instance_methods.collect { |m| m.to_s }.include? "new_#{@model}"
        raise "no model template for #{@klass.name}"
      end

      validations.each do |v|
        test = send "validation_lambda_for_#{v}", @klass, @model, attribute
        define_method "test_#{attribute}_#{v}", &test
      end
    end

    private

    def validation_lambda_for_presence klass, model, attribute
      lambda do
        assert_invalid attribute, send("new_#{model}_without", attribute)
      end
    end

    def validation_lambda_for_uniqueness klass, model, attribute
      lambda do
        existing = klass.first
        assert_not_nil existing, "There's at least one #{model} fixture."

        assert_invalid attribute,
          send("new_#{model}", attribute => existing.send(attribute))
      end
    end
  end
end
