module JSON
  REPLACEMENTS = {
    '\\' => '\\\\',
    '"'  => '\\"',
    '/'  => '\/',
    "\b" => '\\b',
    "\f" => '\\f',
    "\n" => '\\n',
    "\r" => '\\r',
    "\t" => '\\t'
  }
  
  def self.generate(object)
    serialize(object)
  end
  
  def self.serialize(object)
    case object
    when Hash
      self._serialize_hash(object)
    when Array
      self._serialize_array(object)
    when String
      self._serialize_string(object)
    when FalseClass
      'false'
    when TrueClass
      'true'
    when NilClass
      'null'
    else
      object.respond_to?(:to_json) ? object.to_json : object.to_s
    end
  end
  
  def self._serialize_string(object)
    escaped = object.gsub(/[\\\"\/\b\f\n\r\t]/) do |match|
      REPLACEMENTS[match]
    end
    "\"#{escaped}\""
  end
  
  def self._serialize_hash(object)
    out = '{'
    first = true
    for name, value in object
      first ? first = false : out << ','
      out << JSON.serialize(name) << ':' << JSON.serialize(value)
    end
    out << '}'
  end
  
  def self._serialize_array(object)
    out = '['
    first = true
    for value in object
      first ? first = false : out << ','
      out << JSON.serialize(value)
    end    
    out << ']'
  end
end