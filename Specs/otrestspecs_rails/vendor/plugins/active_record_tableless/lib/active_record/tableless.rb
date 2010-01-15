module ActiveRecord
  module Tableless
    
    def self.included(base)
      # 'base' is assumed to be ActiveRecord::Base
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def tableless( options = {} )
        include ActiveRecord::Tableless::InstanceMethods
        raise "No columns defined" unless options.has_key?(:columns) && !options[:columns].empty?
        
        self.extend(MetaMethods)
        
        for column_args in options[:columns]
          column( *column_args )
        end
        
      end
    end
    
    module MetaMethods 
      def columns()
        @columns ||= []
      end
      
      def column(name, sql_type = nil, default = nil, null = true)
        columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
        reset_column_information
      end
      
      # Do not reset @columns
      def reset_column_information
        generated_methods.each { |name| undef_method(name) }
        @column_names = @columns_hash = @content_columns = @dynamic_methods_hash = @read_methods = nil
      end
    end
    
    module InstanceMethods 
      def create_or_update
        errors.empty?
      end
      
      def saved!(with_id = 1)
        self.id = with_id
        
        def self.new_record?
          false
        end
      end
      alias_method :exists!, :saved!
    end
    
  end
end