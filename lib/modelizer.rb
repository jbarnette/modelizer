module Modelizer
  @@cache = {}
  def self.cache; @@cache end

  def self.included target
    target.extend ClassMethods
  end

  def assign_model_template_attributes model, attributes
    model.send :attributes=, attributes, false
    model
  end

  def valid_model_template_attributes klass, extras = {}
    defaults, block = ::Modelizer.cache[klass]
    lazy = block && instance_eval(&block)
    [defaults, lazy, extras].compact.inject { |t, s| t.merge s }
  end

  def valid_model_template_attributes_without klass, excluded
    valid_model_template_attributes(klass).delete_if do |k, v|
      excluded.include? k
    end
  end

  module ClassMethods
    def model_template_for klass, defaults = {}, &block
      if defaults.empty? && !block
        raise "default attributes or lazy block required"
      end

      ::Modelizer.cache[klass] = [defaults, block]

      klass = klass.name
      model = klass.underscore.tr "/", "_"

      module_eval <<-END, __FILE__, __LINE__ + 1
        def valid_#{model}_attributes extras = {}
          valid_model_template_attributes #{klass}, extras
        end

        def valid_#{model}_attributes_without *excluded
          valid_model_template_attributes_without #{klass}, excluded
        end

        def new_#{model} extras = {}
          assign_model_template_attributes #{klass}.new,
            valid_model_template_attributes(#{klass}, extras)
        end

        def new_#{model}_without *excluded
          assign_model_template_attributes #{klass}.new,
            valid_model_template_attributes_without(#{klass}, excluded)
        end

        def create_#{model} extras = {}
          (m = new_#{model}(extras)).save; m
        end

        def create_#{model}! extras = {}
          (m = new_#{model}(extras)).save!; m
        end

        def create_#{model}_without *excluded
          (m = new_#{model}_without(*excluded)).save; m
        end

        def create_#{model}_without! *excluded
          (m = new_#{model}_without(*excluded)).save!; m
        end
      END

      # Install a test that ensures the model template is valid. If
      # the template is defined in one of the abstract test
      # superclasses, generate a whole new testcase. If it's in a
      # concrete test, just generate a method.

      file, line = caller.first.split ":"
      line = line.to_i

      test =<<-END
        def test_model_template_for_#{model}
          assert (m = new_#{model}).valid?,
            "#{klass} template is invalid: " +
              m.errors.full_messages.to_sentence
        end
      END

      if self == Test::Unit::TestCase
        eval <<-END, nil, file, line - 2
          class ::ModelTemplateFor#{klass}Test < ActiveSupport::TestCase
            #{test}
          end
        END
      else
        module_eval test, file, line - 1
      end
    end
  end
end