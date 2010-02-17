# Copyright (c) 2008 Phusion
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module DefaultValueForPlugin
	class NormalValueContainer
		def initialize(value)
			@value = value
		end
	
		def evaluate(instance)
			return @value
		end
	end
	
	class BlockValueContainer
		def initialize(block)
			@block = block
		end
	
		def evaluate(instance)
			return @block.call(instance)
		end
	end
	
	module ClassMethods
		def default_value_for(attribute, value = nil, &block)
			if !method_defined?(:initialize_with_defaults)
				include(InstanceMethods)
				alias_method_chain :initialize, :defaults
				class_inheritable_accessor :_default_attribute_values
				self._default_attribute_values = ActiveSupport::OrderedHash.new
			end
			if block_given?
				container = BlockValueContainer.new(block)
			else
				container = NormalValueContainer.new(value)
			end
			_default_attribute_values[attribute.to_s] = container
		end
		
		def default_values(values)
			values.each_pair do |key, value|
				if value.kind_of? Proc
					default_value_for(key, &value)
				else
					default_value_for(key, value)
				end
			end
		end
	end
	
	module InstanceMethods
		def initialize_with_defaults(attrs = nil)
			initialize_without_defaults(attrs) do
				if attrs
					stringified_attrs = attrs.stringify_keys
					safe_attrs = remove_attributes_protected_from_mass_assignment(stringified_attrs)
					safe_attribute_names = safe_attrs.keys.map do |x|
						x.to_s
					end
				end
				self.class._default_attribute_values.each do |attribute, container|
					if safe_attribute_names.nil? || safe_attribute_names.none? { |attr_name| attr_name =~ /^#{attribute}($|\()/ }
						__send__("#{attribute}=", container.evaluate(self))
						changed_attributes.delete(attribute)
					end
				end
				yield(self) if block_given?
			end
		end
	end
end

ActiveRecord::Base.extend(DefaultValueForPlugin::ClassMethods)
