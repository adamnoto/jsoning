class Jsoning::Version
  attr_reader :version_name

  # the protocol class
  attr_reader :protocol

  attr_reader :mappers
  attr_reader :mappers_order

  def initialize(protocol)
    @protocol = protocol
    # mappers, only storing symbol of mapped values
    @mappers_order = []
    @mappers = {}
  end

  def add_mapper(mapper)
    raise Jsoning::Error, "Mapper must be of class Jsoning::Mapper" unless mapper.is_a?(Jsoning::Mapper)
    @mappers_order << canonical_name(mapper.name)
    @mappers[canonical_name(mapper.name)] = mapper
  end

  def mapper_for(name)
    @mappers[canonical_name(name)]
  end
end
