class Jsoning::ForDsl
  attr_reader :protocol

  def initialize(protocol)
    @protocol = protocol
  end

  # args is first specifying the name for variable to be displayed in JSON docs,
  # and then the options. options are optional, if set, it can contains:
  # - from
  # - null
  # - default
  def key *args
    mapped_to = nil
    mapped_from = nil
    options = {}

    args.each do |arg|
      if arg.is_a?(String) || arg.is_a?(Symbol)
        mapped_to = arg
      elsif arg.is_a?(Hash)
        options = arg
      end
    end

    mapper = Jsoning::Mapper.new
    if block_given?
      raise Jsoning::Error, "Cannot parse block to key"
    else
      mapped_from = options.delete(:from) || options.delete("from") || mapped_to
      mapper.parallel_variable = mapped_from
    end

    mapper.name = mapped_to
    mapper.default_value = options.delete(:default) || options.delete("default")
    mapper.nullable = options.delete(:null)
    mapper.nullable = options.delete("null") if mapper.nullable.nil?

    options.keys { |key| raise Jsoning::Error, "Undefined option: #{key}" }

    protocol.add_mapper mapper
  end
end
