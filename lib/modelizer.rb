require "zlib"

module Modelizer
  def build name, overrides = nil, &block
    model, *initializers = Modelizer.factories[name]
    raise "Can't find the \"#{name}\" factory." unless model

    obj = model.new

    initializers << block if block_given?
    initializers.each { |i| instance_exec obj, &i }

    overrides.each { |k, v| obj.send "#{k}=", v } if overrides
    
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

  class Context < Struct.new(:instances)
    def identify name
      Modelizer.identify name
    end

    def use name
      instances[name] or raise "Can't find the \"#{name}\" fixture."
    end
  end

  def self.included klass
    Dir[glob].sort.each { |f| instance_eval File.read(f), f, 1 }

    instances = {}
    context   = Context.new instances

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
      instances.each { |_, obj| obj.save! }
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
end
