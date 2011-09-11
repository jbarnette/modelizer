module Modelizer
  module Validations
    def test_presence_for plan, attribute
      define_method "test_#{attribute}_presence" do
        bad = build plan, attribute => nil
        assert_invalid attribute, bad
      end
    end

    def test_uniqueness_for plan, attribute
      define_method "test_#{attribute}_uniqueness" do
        good = create plan
        bad  = build(plan) { |o| o.send("#{attribute}=", good.send(attribute)) }
        assert_invalid attribute, bad
      end
    end

    def test_validations_for plan, attribute, *validations
      validations.each do |validation|
        send "test_#{validation}_for", plan, attribute
      end
    end
  end
end
