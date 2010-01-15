module SeedFu
  class Seeder
    def self.plant(model_class, *constraints, &block)
      constraints = [:id] if constraints.empty?
      seed = Seeder.new(model_class)
      insert_only = constraints.last.is_a? TrueClass
      constraints.delete_at(*constraints.length-1) if (constraints.last.is_a? TrueClass or constraints.last.is_a? FalseClass)
      seed.set_constraints(*constraints)
      yield seed
      seed.plant!(insert_only)
    end

    def initialize(model_class)
      @model_class = model_class
      @constraints = [:id]
      @data = {}
    end

    def set_constraints(*constraints)
      raise "You must set at least one constraint." if constraints.empty?
      @constraints = []
      constraints.each do |constraint|
        raise "Your constraint `#{constraint}` is not a column in #{@model_class}. Valid columns are `#{@model_class.column_names.join("`, `")}`." unless @model_class.column_names.include?(constraint.to_s)
        @constraints << constraint.to_sym
      end
    end

    def plant! insert_only=false
      record = get
      return if !record.new_record? and insert_only
      @data.each do |k, v|
        record.send("#{k}=", v)
      end
      raise "Error Saving: #{record.inspect}" unless record.save(false)
      puts " - #{@model_class} #{condition_hash.inspect}"      
      record
    end

    def method_missing(method_name, *args) #:nodoc:
      if args.size == 1 and (match = method_name.to_s.match(/(.*)=$/))
        self.class.class_eval "def #{method_name} arg; @data[:#{match[1]}] = arg; end"
        send(method_name, args[0])
      else
        super
      end
    end

    protected

    def get
      records = @model_class.find(:all, :conditions => condition_hash)
      raise "Given constraints yielded multiple records." unless records.size < 2
      if records.any?
        return records.first
      else
        return @model_class.new
      end
    end

    def condition_hash
      @constraints.inject({}) {|a,c| a[c] = @data[c]; a }
    end
  end
end


class ActiveRecord::Base
  # Creates a single record of seed data for use
  # with the db:seed rake task. 
  # 
  # === Parameters
  # constraints :: Immutable reference attributes. Defaults to :id
  def self.seed(*constraints, &block)
    SeedFu::Seeder.plant(self, *constraints, &block)
  end

  def self.seed_many(*constraints)
    seeds = constraints.pop
    seeds.each do |seed_data|
      seed(*constraints) do |s|
        seed_data.each_pair do |k,v|
          s.send "#{k}=", v
        end
      end
    end
  end
end
