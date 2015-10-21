# jsoning can output to conform to different versioning
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

  def version_name=(version_name)
    # version name is always be a string, because if user's version
    # name happen to be an integer, we don't want to fail on that case
    @version_name = version_name.to_s
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
