module ActsAsUrlParam
  def self.included(base)
    base.extend ActMethods
  end
  
  module ActMethods
    
    def acts_as_url_param(*args, &block)
      return unless table_exists?
      extend ClassMethods
      include InstanceMethods
      include Caring::Utilities::UrlUtils
      extend Caring::Utilities::UrlUtils
      
      class_inheritable_accessor :acts_as_url_options, :acts_as_url_param_base
      # No extract options in rails 1.2.x
      options = args.respond_to?(:extract_options!) ? args.extract_options! : extract_options_from_args!(args)
      self.acts_as_url_options = options
      options[:column] = args.first || 'url_name'
      options[:from] ||= default_from_column
      
      if options[:redirectable]
        options[:on] ||= :update
        make_redirectable
      end
      
      options[:on] ||= :create
      options[:block] = block if block_given?
      callback = "before_validation"
      if options[:on] == :create
        callback += "_on_create"
        before_validation :set_url_param_if_non_existant
      end
      send callback, :set_url_param
      validates_presence_of(options[:from], :if => :empty_param?) unless options[:allow_blank]
      
      define_finder
      define_url_param_setter
      define_availability_check
      
      self.class_eval do
        alias_method_chain :validate, :unique_url unless method_defined? :validate_without_unique_url
      end
    end
    
    private
    
    def make_redirectable
      has_many :redirects, :as => :redirectable, :dependent => :destroy
      before_save :add_redirect
      
      class_def :add_redirect do
        if !new_record? && url_to_field_changed?
          redirects.create(:url_name => url_to_field_was) unless url_to_field_was.blank?
        end
      end
      
      meta_def :find_redirect do |name|
        redirect = Redirect.find_by_class_and_name(self,name)
        redirect.redirectable if redirect
      end
    end
    
    def define_finder
      meta_def :find_by_url do |*args|
        send("find_by_#{acts_as_url_options[:column]}", *args)
      end
      send(:named_scope, "with_url", lambda{|url|
        {:conditions => ["#{acts_as_url_options[:column]} = ?", url]}
      })
    end
    
    def define_url_param_setter
      class_def "#{acts_as_url_options[:column]}=" do |value|
        super url_safe(value)
        # @url_name_manually_set = true if value
        # @old_name = read_attribute(acts_as_url_options[:column]) unless @name_changed
        # write_attribute(acts_as_url_options[:column], url_safe(value))
        # @name_changed = true unless read_attribute(acts_as_url_options[:column]) == @old_name || !@old_name
      end
    end
    
    def define_availability_check
      klass = self
      meta_def :url_param_available_for_model? do |*args|
        candidate, record = *args
        id = record && !record.new_record? && record.id
        if acts_as_url_options[:scope]
          base = record || self
          conditions = base.send(:instance_eval, "\"#{acts_as_url_options[:scope]}\"") + ' AND '
        end
        conditions ||= '' 
        conditions += "#{acts_as_url_options[:column]} = ?"
        conditions += " AND id != ?" if id
        conditions += " AND type = ? " if acts_as_url_options[:scope] == :type
        conditions = [conditions, candidate]
        conditions << id if id
        conditions << self.to_s if acts_as_url_options[:scope] == :type
        available = if descends_from_active_record? or self == klass
          count(:conditions => conditions) == 0
        else
          base_class.count(:conditions => conditions) == 0
        end
        logger.debug("conditions are #{conditions.inspect}")
        if acts_as_url_options[:redirectable] && available
          re_conditions = "url_name = ? AND redirectable_class = ?"
          re_conditions += "AND redirectable_id != ?" if id
          re_conditions = [re_conditions, candidate, self.to_s]
          re_conditions << id if id
          available = Redirect.count(:conditions => re_conditions) == 0
        end
        available
      end
    end
    
    def default_from_column
      %W(name label title).detect do |column_name|
        column_or_method_exists?(column_name) and self.acts_as_url_options[:to].to_s != column_name
      end
    end
    
    def column_or_method_exists?(name)
      column_names.include? name.to_s or method_defined? name
    end
    
    module ClassMethods
      def url_param_available?(candidate, record=nil)
        if proc = acts_as_url_options[:block]
          if proc.arity == 1
            proc.call(candidate)
          else
            proc.call(candidate, record)
          end
        else
          url_param_available_for_model?(candidate, record)
        end
      end
      
      def compute_url_param(candidate, record=nil)
        return if candidate.blank?
        # raise ArgumentError, "The url canidate cannot be empty" if candidate.blank?
        uniquify_proc = acts_as_url_options[:block] || Proc.new { |candidate| url_param_available? candidate, record }
        uniquify(url_safe(candidate), &uniquify_proc)
      end
    end
    
    module InstanceMethods
      def compute_url_param
        # raise ArgumentError, "The column used for generating the url_param is empty" unless url_from
        self.class.compute_url_param(url_from, self)
      end
      
      def url_from
        url_from_method? ? send(acts_as_url_options[:from]) : read_attribute(acts_as_url_options[:from])
      end
      
      def to_param
        url_param || id.to_s
      end
      
      def url_param
        read_attribute(acts_as_url_options[:column])
      end
      
      private
      
      def empty_param?
        !url_param
      end
      
      def update_url?
        url_to_field_changed? && !url_from_field_changed?
      end

      def url_to_field_changed?
        send("#{acts_as_url_options[:column]}_changed?")
      rescue NoMethodError
      end

      def url_to_field_was
        send("#{acts_as_url_options[:column]}_was")
      end

      def url_from_field_changed?
        send("#{acts_as_url_options[:from]}_changed?")
      rescue NoMethodError
        true
      end
      
      def url_from_method?
        self.class.method_defined?(acts_as_url_options[:from])
      end
      
      def set_url_param_if_non_existant
        unless new_record?
          set_url_param if url_param.blank?
        end
      end
      
      def set_url_param?
        url_param.blank? or
          (url_from_field_changed? && 
          acts_as_url_options[:on] != :create && 
          !url_to_field_changed?)
      end
      
      def set_url_param
        if set_url_param?
          send(acts_as_url_options[:before]) if acts_as_url_options[:before]
          url = compute_url_param
          send("#{acts_as_url_options[:column]}=", url) unless url.blank?
          @url_param_validated = true
        end
      end
      
      def validate_with_unique_url
        if @url_param_validated or (!new_record? && !url_to_field_changed? && !url_from_field_changed?)
          return true 
        end
        unless self.class.url_param_available? to_param, self
          errors.add_to_base "The url is not unique"
        end
        validate_without_unique_url
      end
    end
  end
end
