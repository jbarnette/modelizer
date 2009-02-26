require "minitest/unit"
require "activesupport"
require "modelizer"

class TestModelizer < MiniTest::Unit::TestCase
  def setup
    @klass = Class.new
    @klass.send :include, Modelizer
  end

  def test_adds_model_template_for_class_method
    assert_includes @klass.singleton_methods.collect { |m| m.to_s },
      "model_template_for"
  end
end
