# takes care of the class
class Jsoning::Protocol
  attr_reader :klass
  attr_reader :version_instances

  def initialize(klass)
    @klass = klass
    @version_instances = {}

    # each protocol has a default version named :default
    add_version(:default)

    self
  end

  # add a new version, a protocol can handle many version
  # to export the JSON
  def add_version(version_name)
    unless version_name.is_a?(String) || version_name.is_a?(Symbol)
      fail "Version name must be either a String or a Symbol"
    end
    version = Jsoning::Version.new(self)
    version.version_name = version_name
    @version_instances[version.version_name] = version
    version
  end

  # retrieve a defined version, or return nil if undefined
  def get_version(version_name)
    @version_instances[version_name.to_s]
  end

  # retrieve a defined version, or fail if undefined
  def get_version!(version_name)
    version = get_version(version_name)
    fail Jsoning::Error, "Unknown version: #{version_name}" if version.nil?
    version
  end

  # construct the JSON from given object
  # options:
  #  - version: the version to be used for processing 
  def retrieve_values_from(object, options)
    # user will pass in version, rather than version_name, although actually
    # it is a version_name instead of version instance
    version_name = options[:version]
    version = get_version!(version_name)

    # hold data here
    data = {}

    version.mappers_order.each do |mapper_sym|
      mapper = version.mapper_for(mapper_sym)
      mapper.extract(object, data)
    end

    data
  end

  # construct hash from given JSON
  def construct_hash_from(json_string)
    data = {}

    # make all json obj keys to downcase, symbol
    json_obj = JSON.parse(json_string)
    json_obj = Hash[json_obj.map { |k, v| [k.to_s.downcase, v]}]

    mappers_order.each do |mapper_sym|
      mapper = mapper_for(mapper_sym)
      mapper_key_name = mapper.name.to_s.downcase
      
      mapper_default_value = mapper.default_value
      mapper_key_value = json_obj[mapper_key_name]
      # retrieve value from key, if not available, from default
      value = mapper_key_value || mapper_default_value

      if value.nil? && !mapper.nullable?
        raise Jsoning::Error, "Constructing hash failed due to #{mapper_key_name} being nil when it is not allowed to" 
      end

      data[mapper_key_name] = value
    end

    data
  end
end
