require "jsoning/version"

require "jsoning/dsl/for_dsl"
require "jsoning/exceptions/error"
require "jsoning/foundations/mapper"
require "jsoning/foundations/protocol"

require "json"

module Jsoning
  PROTOCOLS = {}
  # if type is defined here, we will use it to extract its value for the key
  TYPE_EXTENSIONS = {}

  module_function

  # returns a protocol, or create one if none exists
  def protocol_for(klass)
    protocol = PROTOCOLS[klass.to_s]
    if protocol.nil?
      protocol = Jsoning::Protocol.new(klass)
      PROTOCOLS[klass.to_s] = protocol
    end
    protocol
  end

  def protocol_for!(klass)
    protocol = PROTOCOLS[klass.to_s]
    raise Jsoning::Error, "Undefined Jsoning protocol for #{klass.to_s}" if protocol.nil?
    protocol
  end

  def clear
    PROTOCOLS.clear
  end

  def for(klass, &block)
    Jsoning::ForDsl.new(protocol_for(klass)).instance_eval(&block)
  end

  def generate(object, options = {})
    protocol = protocol_for!(object.class)
    protocol.generate(object, options)
  end

  class << self
    def add_type(klass, options = {})
      processor = options[:processor]
      raise Jsoning::Error, "Pass in processor that is a proc explaining how to extract the value" unless processor.is_a?(Proc)

      TYPE_EXTENSIONS[klass.to_s] = processor
      nil
    end
  end
  
  def self.[](object) 
    protocol = protocol_for!(object.class)
    protocol.parse(object)
  end

  # monkey patch Kernel
  module ::Kernel
    private

    def Jsoning(object, options = {})
      Jsoning.generate(object, options)
    end
  end
end
