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

  # retrieve the protocol or raise an error when the protocol is not defined yet
  def protocol_for!(klass)
    protocol = PROTOCOLS[klass.to_s]
    raise Jsoning::Error, "Undefined Jsoning protocol for #{klass.to_s}" if protocol.nil?
    protocol
  end

  # clearing the protocols
  def clear
    PROTOCOLS.clear
  end

  # define the protocol
  def for(klass, &block)
    Jsoning::ForDsl.new(protocol_for(klass)).instance_eval(&block)
  end

  # generate the json document
  def generate(object, options = {})
    initialize_type_extensions 
    protocol = protocol_for!(object.class)
    protocol.generate(object, options)
  end

  @@type_extension_initialized = false
  def initialize_type_extensions
    @@type_extension_initialized = true if !!@@type_extension_initialized
    return if @@type_extension_initialized

    begin
      require "time"
      ::Time
      self.add_type Time, processor: proc { |time| time.iso8601 }
    rescue
    end

    begin
      # try to define value extractor for ActiveSupport::TimeWithZone which is in common use
      # for AR model
      ::ActiveSupport::TimeWithZone
      self.add_type ActiveSupport::TimeWithZone, processor: proc { |time| time.send(:iso8601) }
    rescue 
      # nothing, don't add
    end

    begin
      ::DateTime
      self.add_type DateTime, processor: proc { |date| date.send(:iso8601) }
    rescue => e 
      # nothing, don't add
    end

    begin
      ::Date
      self.add_type Date, processor: proc { |date| date.send(:iso8601) }
    rescue 
      # nothing, don't add
    end
  end

  def add_type(klass, options = {})
    processor = options[:processor]
    raise Jsoning::Error, "Pass in processor that is a proc explaining how to extract the value" unless processor.is_a?(Proc)

    TYPE_EXTENSIONS[klass.to_s] = processor
    nil
  end
  
  def [](object) 
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

  # parse the JSON String to Hash
  def parse(json_string)

  end
end
