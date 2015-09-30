require "jsoning/version"

require "jsoning/dsl/for_dsl"
require "jsoning/exceptions/error"
require "jsoning/foundations/mapper"
require "jsoning/foundations/protocol"

require "json"

module Jsoning
  PROTOCOLS = {}

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

  # monkey patch Kernel
  module ::Kernel
    private

    def Jsoning(object, options = {})
      Jsoning.generate(object, options)
    end
  end
end
