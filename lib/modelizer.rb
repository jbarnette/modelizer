require "zlib"

module Modelizer

  VERSION = "5.0.2"

  module Helpers
    def build name, overrides = nil, &block
      model, *initializers = Modelizer.factories[name]
      raise "Can't find the \"#{name}\" factory." unless model

      obj = model.new
      ctx = FactoryContext.new overrides || {}

      initializers << block if block_given?

      initializers.each { |i| ctx.instance_exec obj, &i }
      overrides.each    { |k, v| obj.send "#{k}=", v } if overrides
      
      obj
    end

    def create name, overrides = nil, &block
      obj = build name, overrides, &block

      obj.save!

      obj
    end

    def use name
      model, id = Modelizer.ids[name]
      raise "Can't find the \"#{name}\" fixture." unless model

      model.find id
    end
  end

  include Helpers

  def self.included klass
    Dir[glob].sort.each { |f| instance_eval File.read(f), f, 1 }

    instances = {}
    context   = FixtureContext.new instances

    fixtures.each do |name, value|
      instances[name] = value.first.new
    end

    instances.each do |name, obj|
      _, *initializers = fixtures[name]
      initializers.each { |i| context.instance_exec obj, &i }

      obj.id    = identify name
      ids[name] = [obj.class, obj.id]
    end

    ActiveRecord::Base.transaction do
      instances.each do |name, obj|
        unless obj.save
          raise "'#{name}' fixture can't be saved: #{obj.errors.full_messages}"
        end
      end
    end
  end

  class << self
    attr_accessor :glob
  end

  self.glob = "test/{factories,fixtures}/**/*.rb"

  def self.cache
    @cache ||= {}
  end

  def self.factory name, model, &initializer
    factories[name] = [model, initializer]
  end

  def self.factories
    @factories ||= {}
  end

  def self.fixture name, model, &initializer
    fixtures[name] = [model, initializer]
  end

  def self.fixtures
    @fixtures ||= {}
  end

  def self.identify name
    Zlib.crc32(name.to_s) % (2 ** 30 - 1)
  end

  def self.ids
    @ids ||= {}
  end

  class FactoryContext < Struct.new(:overrides)
    include Helpers

    def build name, *args, &block
      self.overrides[name] || super
    end
  end

  class FixtureContext < Struct.new(:instances)
    def identify name
      Modelizer.identify name
    end

    def use name
      instances[name] or raise "Can't find the \"#{name}\" fixture."
    end
  end
end
