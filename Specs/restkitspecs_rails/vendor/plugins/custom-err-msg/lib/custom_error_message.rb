module CustomErrorMessage
  def self.included(receiver)
    receiver.send :include, InstanceMethods
    receiver.class_eval do
      alias_method_chain :full_messages, :tilde
      alias_method_chain :add, :procs
    end
  end

  module InstanceMethods
    # Redefine the full_messages method:
    #  Returns all the full error messages in an array. 'Base' messages are handled as usual.
    #  Non-base messages are prefixed with the attribute name as usual UNLESS they begin with '^'
    #  in which case the attribute name is omitted.
    #  E.g. validates_acceptance_of :accepted_terms, :message => '^Please accept the terms of service'

    private
    def full_messages_with_tilde
      full_messages = full_messages_without_tilde
      full_messages.map do |message|
        if starts_with_humanized_column_followed_by_circumflex? message
          message.gsub(/^.+\^/, '')
        else
          message
        end
      end
    end

    def add_with_procs(attribute, message = nil, options = {})
      if options[:default].respond_to? :to_proc
        options[:default] = "^#{options[:default].to_proc.call(@base)}"
      end
      
      add_without_procs(attribute, message, options)
    end

    def starts_with_humanized_column_followed_by_circumflex?(message)
      @errors.keys.any? do |column| 
        humanized = @base.class.human_attribute_name column.split('.').last.to_s
        message.match(/^#{humanized} \^/)
      end
    end
  end
end
