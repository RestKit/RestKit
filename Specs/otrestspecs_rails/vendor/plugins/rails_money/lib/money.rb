# Money class. 
# This stores the value of the price in cents, and can be initialized with
# a Float (dollars.cents) or Integer (dollars). To create a money object from
# cents, use create_from_cents (Money.create_from_cents(500) and Money.new(5) are
# the same).
# 
# If a String is passed, it will do it's best to figure turn it into a float. 
# This means "$10.00" and "$10 dollars" would both be treated as 10.00
#
# The following article by Martin Fowler was used as a reference:
#   http://www.martinfowler.com/ap2/quantity.html
#


raise "Another Money Object is already defined!" if Object.const_defined?(:Money)

class MoneyError < StandardError; end;
class Money
  include Comparable
  attr_reader :cents
  
  # Create a new Money object with value. Value can be a Float (Dollars.cents) or Fixnum (Dollars).
  def initialize(value)
    @cents = (Money.get_value(value)*100.0).round
  end

  # Create a new Money object with a value representing cents.
  def self.create_from_cents(value)
    return Money.new(Money.get_value(value)/100.0)
  end
    
  # Equality. 
  def eql?(other)
    cents <=> other.to_money.cents
  end

  # Equality for Comparable.
  def <=>(other)
    eql?(other)
  end

  # Add Fixnum, Float, or Money and return result as a Money object
  def +(other)
    Money.create_from_cents((cents + other.to_money.cents))
  end

  # Subtract Fixnum, Float, or Money and return result as a Money object
  def -(other)
    Money.create_from_cents((cents - other.to_money.cents))
  end
  
  # Multiply by fixnum and return result as a Money object
  def *(other)
    Money.create_from_cents((cents * other).round)
  end
  
  # Divide by fixnum and return result as a Money object
  def /(denominator)
    raise MoneyError, "Denominator must be a Fixnum. (#{denominator} is a #{denominator.class})"\
      unless denominator.is_a? Fixnum

    result = []
    equal_division = (cents / denominator).round
    denominator.times { result << Money.create_from_cents(equal_division) }
    extra_pennies = cents - (equal_division * denominator)
    
    # Make sure we don't loose any pennies!
    extra_pennies.times { |p| result[p] += 0.01 }
    result
  end
  
  def abs
    return Money.create_from_cents cents.abs
  end

  # Is this free?
  def free?
    return (cents == 0)
  end
  alias zero? free?

  # Return the value in cents
  def cents
    @cents
  end  

  # Return the value in dollars
  def dollars
    cents.to_f / 100
  end

  # Return the value in a string (in dollars)
  # if a zero_string is provided like "FREE" or "FREE!" or "$ --.--"
  # it will be returned instead of "$0.00"
  def to_s(zero_string=nil)
    return zero_string if zero_string && free?
    seperated = "#{sprintf("%.2f",dollars)}".to_s.split(".")
    if dollars >= 0
      seperated[0] = seperated[0].to_s.reverse.scan(/..?.?/).join(",").reverse
      "$#{seperated.join(".")}"
    else
      seperated[0] = seperated[0].to_s.delete("-").reverse.scan(/..?.?/).join(",").reverse
      "-$#{seperated.join(".")}"
    end
  end

  # Conversion to self
  def to_money
    self
  end

  private 
  # Get a value in preperation for creating a new Money object. 
  def self.get_value(value)
    return value.dollars if value.is_a?(Money)
    value = value.gsub(/[^0-9.]/,'').to_f if value.kind_of?(String) 
    value = 0 if value.nil?
    unless value.kind_of?(Integer) or value.kind_of?(Float)
      raise MoneyError, "Cannot create money from cents with #{value.class}. Fixnum required." 
    end
    value
  end

end

class Numeric
  # Creates a new money object with the value of the +Numeric+ object.
  #   100.to_money => #<Money @cents=100>
  #   100.00.to_money => #<Money @cents=10000>
  #   100.37.to_money => #<Money @cents=10037>
  def to_money
    Money.new(self)
  end
end

