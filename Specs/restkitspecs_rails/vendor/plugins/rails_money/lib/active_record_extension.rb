module RailsMoney
  def method_missing( method_id, *args )
    method_name = method_id.to_s
    setter = method_name.chomp!("=")
    method_name = "#{method_name}_in_cents"

    if @attributes.include?(method_name)
      if setter
        money = args.first.kind_of?(Money) ? args.first : Money.new(args.first)
        write_attribute(method_name,money.cents) 
      else
        Money.create_from_cents(read_attribute(method_name))      
      end
    else 
      super
    end
  end
 
  def respond_to?( method, include_private = false )
    method_name = method.to_s.chomp("=")
    @attributes.include?("#{method_name}_in_cents") || super
  end
end

ActiveRecord::Base.send :include, RailsMoney
