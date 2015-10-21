class Jsoning::ForDsl
  attr_reader :protocol
  attr_reader :current_version_object
  @@mutex = Mutex.new

  def initialize(protocol)
    @protocol = protocol
  end

  # specify the version under which key will be executed
  def version(version_name)
    @@mutex.synchronize do
      fail Jsoning::Error, "Version cannot be nested" if current_version_object

      # retrieve the version, or create a new one if not yet defined
      version = protocol.get_version(version_name)
      version = protocol.add_version(version_name) if version.nil?

      self.current_version_object = version
    end
    self.current_version_object = nil
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

    # get the version instance
    version_instance = if self.current_version_object.nil?
      protocol.get_version!(:default)
    else
      current_version_object
    end 

    mapper = Jsoning::Mapper.new(version_instance)
    if block_given?
      raise Jsoning::Error, "Cannot parse block to key"
    else
      mapped_from = options.delete(:from) || options.delete("from") || mapped_to
      mapper.parallel_variable = mapped_from
    end

    mapper.name = mapped_to
    mapper.default_value = options.delete(:default) || options.delete("default")
    mapper.nullable = options.delete(:null)
    mapper.nullable = options.delete("null") if mapper.nullable?.nil?

    options.keys { |key| raise Jsoning::Error, "Undefined option: #{key}" }

    # add mapper to the version
    version_instance.add_mapper(mapper)
  end
end
