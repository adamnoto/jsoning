# takes care of the class
class Jsoning::Protocol
  attr_reader :klass
  attr_reader :mappers
  attr_reader :mappers_order

  def initialize(klass)
    @klass = klass

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

  # generate a JSON object
  # options:
  # - pretty: pretty print json data
  def generate(object, options = {})
    pretty = options[:pretty]
    pretty = options["pretty"] if pretty.nil?
    pretty = false if pretty.nil?

    data = parse(object)

    if pretty
      JSON.pretty_generate(data)
    else
      JSON.generate(data)
    end
  end

  def parse(object)
    # hold data here
    data = {}

    mappers_order.each do |mapper_sym|
      mapper = mapper_for(mapper_sym)
      mapper.extract(object, data)
    end

    data
  end

  private
  def canonical_name(key_name)
    key_name.to_s.downcase.to_sym
  end
end
