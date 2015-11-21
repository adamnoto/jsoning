# responsible of mapping from object to representable values, one field at a time
class Jsoning::Mapper
  # access to a version instance
  attr_accessor :version

  # when mapped, what will be the mapped name
  attr_writer :name

  attr_writer :default_value
  attr_writer :nullable
  # what variable in the object will be used to obtain the value
  attr_accessor :parallel_variable
  attr_accessor :value_processor

  def initialize(version_instance)
    self.parallel_variable = nil
    @default_value = nil
    self.nullable = true
    self.version = version_instance
  end

  def nullable?
    if @nullable.is_a?(TrueClass) || @nullable.is_a?(FalseClass)
      return @nullable
    else
      # by default, allow every mapped things to be nil
      true
    end
  end

  def name
    @name_as_string = @name.to_s if @name_as_string.nil?
    @name_as_string
  end

  # map this very specific object's field to target_hash
  def extract(object, requested_version_name, target_hash)
    target_value = nil

    if object.respond_to?(parallel_variable)
      parallel_val = object.send(parallel_variable)
      target_value = parallel_val
    end

    if target_value.nil?
      target_value = self.default_value(requested_version_name)
      if target_value.nil? && !self.nullable?
        raise Jsoning::Error, "Null value given for '#{name}' when serializing #{object}"
      end
    end

    # apply extractor to extracted value, if processor is defined
    if value_processor
      target_value = deep_parse(target_value, requested_version_name, false)
      target_value = value_processor.(target_value)
    else
      target_value = deep_parse(target_value, requested_version_name, true)
    end

    target_hash[name] = target_value
  end

  def default_value(version_name = self.version.version_name)
    if @default_value
      if @default_value.is_a?(Proc)
        return deep_parse(@default_value.(), version_name, true)
      else
        return deep_parse(@default_value, version_name, true)
      end
    else
      nil
    end
  end

  private
    def deep_parse(object, version_name, run_value_extractor)
      parsed_data = nil

      value_extractor = Jsoning::TYPE_EXTENSIONS[object.class.to_s]
      if value_extractor && run_value_extractor # is defined
        parsed_data = value_extractor.(object)
      else
        if object.is_a?(Array)
          parsed_data = []
          object.each do |each_obj|
            parsed_data << deep_parse(each_obj, version_name, run_value_extractor)
          end
        elsif object.is_a?(Hash)
          parsed_data = {}
          object.each do |obj_key_name, obj_val|
            parsed_data[obj_key_name] = deep_parse(obj_val, version_name, run_value_extractor)
          end
        elsif object.is_a?(Integer) || object.is_a?(Float) || object.is_a?(String) ||
          object.is_a?(TrueClass) || object.is_a?(FalseClass) || object.is_a?(NilClass)
          parsed_data = object
        else
          if run_value_extractor
            protocol = Jsoning.protocol_for!(object.class)
            parsed_data = protocol.retrieve_values_from(object, {version: version_name})
          else
            # if value extractor is false, don't raise error if protocol is undefined.
            # value processor is exactly way for user to customly extract data in-line
            protocol = Jsoning::PROTOCOLS[object.class]
            if protocol
              parsed_data = protocol.retrieve_values_from(object, {version: version_name})
            else
              parsed_data = object
            end
          end
        end
      end

      parsed_data
    end
end
