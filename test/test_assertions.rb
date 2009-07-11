require "minitest/autorun"
require "modelizer/assertions"

module Modelizer
  class TestAssertions < MiniTest::Unit::TestCase
    include Modelizer::Assertions

    class MockModel
      attr_reader :errors

      def initialize valid, errors = {}
        def errors.on attribute; self[attribute] end
        def errors.full_messages; values end

        @valid  = valid
        @errors = errors
      end

      def valid?; @valid end
    end

    def test_assert_invalid
      model = MockModel.new false, :thing => "is invalid"
      assert_invalid :thing, model
    end

    def test_assert_invalid_fails_fast_for_valid_models
      model = MockModel.new false
      assert_raises(MiniTest::Assertion) { assert_invalid :ignored, model }
    end

    def test_assert_invalid_looks_for_errors_on_attribute
      model = MockModel.new false, :other => "is broken"
      assert_raises(MiniTest::Assertion) { assert_invalid :attribute, model }
    end
  end
end
