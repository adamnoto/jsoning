# takes care of translating/fetching values from the object
class Jsoning::Mapper
  # when mapped, what will be the mapped name
  attr_writer :name

  attr_accessor :default_value
  attr_writer :nullable
  # what variable in the object will be used to obtain the value
  attr_accessor :parallel_variable
  attr_accessor :custom_block

  def initialize
    self.parallel_variable = nil
    self.default_value = nil
    self.nullable = true
  end

  def nullable
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
  def extract(object, target_hash)
    target_value = nil

    if object.respond_to?(parallel_variable)
      parallel_val = object.send(parallel_variable)
      target_value = deep_parse(parallel_val)
    end

    if target_value.nil?
      target_value = self.get_default_value
      if target_value.nil? && !self.nullable
        raise Jsoning::Error, "Null value given for '#{name}' when serializing #{object}"
      end
    end
    target_hash[name] = deep_parse(target_value)
  end

  def get_default_value
    if self.default_value
      if self.default_value.is_a?(Proc)
        return deep_parse(self.default_value.())
      else
        return deep_parse(self.default_value)
      end
    else
      nil
    end
  end

  private
    def deep_parse(object)
      parsed_data = nil

      value_extractor = Jsoning::TYPE_EXTENSIONS[object.class.to_s]
      if value_extractor # is defined
        parsed_data = value_extractor.(object)
      else
        if object.is_a?(Array)
          parsed_data = []
          object.each do |each_obj|
            parsed_data << deep_parse(each_obj)
          end
        elsif object.is_a?(Hash)
          parsed_data = {}
          object.each do |obj_key_name, obj_val|
            parsed_data[obj_key_name] = deep_parse(obj_val)
          end
        elsif object.is_a?(Integer) || object.is_a?(Float) || object.is_a?(String) ||
          object.is_a?(TrueClass) || object.is_a?(FalseClass) || object.is_a?(NilClass)
          parsed_data = object
        else
          protocol = Jsoning.protocol_for!(object.class)
          parsed_data = protocol.parse(object)
        end
      end

      parsed_data
    end
end
