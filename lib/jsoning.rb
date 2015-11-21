require "jsoning/version"

require "jsoning/dsl/for_dsl"
require "jsoning/exceptions/error"
require "jsoning/foundations/protocol"
require "jsoning/foundations/version"
require "jsoning/foundations/mapper"

require "json"

module Jsoning
  PROTOCOLS = {}
  # if type is defined here, we will use it to extract its value for the key
  TYPE_EXTENSIONS = {}

  module_function

  # returns a protocol, or create one if none exists
  def protocol_for_or_create(klass)
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
    Jsoning::ForDsl.new(protocol_for_or_create(klass)).instance_eval(&block)
  end

  # generate the json document
  # options:
  # - hash: specify if the return is a hash
  # - pretty: only for when hash is set to flash, print JSON pretty
  # - version: specify the version to be used for the processing
  def generate(object, options = {})
    Jsoning.initialize_type_extensions
    protocol = protocol_for!(object.class)

    # use default version if version is unspecified 
    options[:version] = :default if options[:version].nil?

    if options[:hash] == true
      return generate_hash(object, protocol, options)
    else
      return generate_json(object, protocol, options)
    end
  end

  # generate a JSON object
  # options:
  # - pretty: pretty print json data
  def generate_json(object, protocol, options)
    pretty = options[:pretty]
    pretty = options["pretty"] if pretty.nil?
    pretty = false if pretty.nil?

    data = protocol.retrieve_values_from(object, options)

    if pretty
      JSON.pretty_generate(data)
    else
      JSON.generate(data)
    end
  end

  def generate_hash(object, protocol, options)
    as_hash = protocol.retrieve_values_from(object, options)
  end

  @@type_extension_initialized = false
  # define value extractor/interpreter for commonly used ruby datatypes that are not
  # part of standard types supported by JSON
  def initialize_type_extensions
    @@type_extension_initialized = true if !!@@type_extension_initialized
    return if @@type_extension_initialized

    begin
      ::Time
      self.add_type ::Time, processor: proc { |time| time.strftime("%FT%T%z") }
    rescue
    end

    begin
      # try to define value extractor for ActiveSupport::TimeWithZone which is in common use
      # for AR model
      ::ActiveSupport::TimeWithZone
      self.add_type ActiveSupport::TimeWithZone, processor: proc { |time| time.strftime("%FT%T%z") }
    rescue 
      # nothing, don't add
    end

    begin
      ::DateTime
      self.add_type ::DateTime, processor: proc { |date| date.strftime("%FT%T%z") }
    rescue => e 
      # nothing, don't add
    end

    begin
      ::Date
      self.add_type ::Date, processor: proc { |date| date.strftime("%FT%T%z") }
    rescue 
      # nothing, don't add
    end
  end

  # using [] will generate using default schema
  def [](object) 
    generate(object, hash: true, version: :default)
  end

  # add custom type explaining to Jsoning how Jsoning should extract value from
  # this kind of class
  def add_type(klass, options = {})
    processor = options[:processor]
    raise Jsoning::Error, "Pass in processor that is a proc explaining how to extract the value" unless processor.is_a?(Proc)
    TYPE_EXTENSIONS[klass.to_s] = processor
    nil
  end

  # monkey patch Kernel
  module ::Kernel
    private

    def Jsoning(object, options = {})
      Jsoning.generate(object, options)
    end
  end

  # parse the JSON String to Hash
  def parse(json_string, klass, version_name = :default)
    Jsoning.initialize_type_extensions 
    protocol = protocol_for!(klass)
    protocol.construct_hash_from(json_string, version_name)
  end
end
