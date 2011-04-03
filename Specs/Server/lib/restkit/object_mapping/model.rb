# TODO: Move this out somewhere/somehow...
# Replace with ActiveModel or something???
class Model
  def self.attributes(*attributes)
    @attributes ||= []
    @attributes += attributes
    attributes.each { |attr| attr_accessor attr }
  end
  
  def self.defined_attributes
    @attributes
  end
  
  def initialize(options = {})
    options.each { |k,v| self.send("#{k}=", v) }
  end
  
  def to_hash
    self.class.defined_attributes.inject({}) { |hash, attr| hash[attr] = self.send(attr); hash }
  end
  
  def to_json
    JSON.generate(self.to_hash)
  end
end
