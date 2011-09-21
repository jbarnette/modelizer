module Modelizer
  module Validations
    def test_presence_for factory, attribute
      define_method "test_#{attribute}_presence" do
        bad = build factory, attribute => nil
        assert_invalid attribute, bad
      end
    end

    def test_uniqueness_for factory, attribute
      define_method "test_#{attribute}_uniqueness" do
        good = create factory
        bad  = build factory, attribute => good.send(attribute)
        assert_invalid attribute, bad
      end
    end

    def test_validations_for factory, attribute, *validations
      validations.each do |validation|
        send "test_#{validation}_for", factory, attribute
      end
    end
  end
end
