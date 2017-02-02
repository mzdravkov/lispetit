require_relative 'types.rb'

module Core
  extend Core

  def type(argument)
    argument.class
  end

  def print(*arguments)
    Kernel.print *arguments
  end

  def println(*arguments)
    Kernel.print *arguments
    puts "\n"
  end

  def list(*arguments)
    Lispetit::List.new arguments
  end

  def macroexpand(argument)
    if argument.is_a? Lispetit::List
      
    else
      argument
    end
  end

  def +(*arguments)
    validate_numerics! :+, arguments

    arguments.reduce(&:+)
  end

  def -(*arguments)
    validate_numerics! :-, arguments

    arguments.reduce(&:-)
  end

  def *(*arguments)
    validate_numerics! :*, arguments

    arguments.reduce(&:*)
  end

  def /(*arguments)
    validate_numerics! :/, arguments

    arguments.reduce(&:/)
  end

  def not(argument)
    return true if argument == false or argument == nil
    false
  end

  def equal?(*arguments)
    validate_count_more_than!(:equal?, arguments.count, 1)

    arguments.all? { |arg| arg == arguments.first }
  end

  def quotient(divident, divisor)
    validate_numerics!(:quotient, [divident, divisor])
    divident.div(divisor)
  end

  def mod(divident, divisor)
    validate_numerics!(:mod, [divident, divisor])
    divident.modulo(divisor)
  end

  def numerator(num)
    validate_numerics!(:numerator, [num])
    num.numerator
  end

  def denominator(num)
    validate_numerics!(:denominator, [num])
    num.denominator
  end

  def abs(num)
    validate_numerics!(:abs, [num])
    num.abs
  end

  def floor(num)
    validate_numerics!(:floor, [num])
    num.floor
  end

  def round(num)
    validate_numerics!(:round, [num])
    num.round
  end

  def ceil(num)
    validate_numerics!(:ceil, [num])
    num.ceil
  end

  def pow(base, degree)
    validate_numerics!(:pow, [base, degree])
    base ** degree
  end

  def call(object, method, *arguments)
    object.public_send(method, *arguments)
  end

  def len(coll)
    validate_type_is_one_of!(:len, coll, Lispetit::List, String)
    coll.length
  end

  def substring(str, from, count)
    str[from, count]
  end

  def upcase(str)
    str.upcase
  end

  def contains?(coll, x)
    coll.include? x
  end

  def methods_hash
    hash = Hash[instance_methods.map { |m| [m.to_s, method(m)] }]
    hash.delete 'methods_hash'
    hash
  end

  private

  def validate_argument_types!(function, arguments)
    arguments.each_pair do |arg, expected_and_value|
      expected, value = expected_and_value
      if value.is_a? expected
        p value.class
        raise ArgumentError.new("Error: #{function} expects argument '#{arg}' to be #{printable_class(expected)}")
      end
    end
  end

  def validate_type_is_one_of!(function, argument, *types)
    unless types.include?(argument.class)
      printable_types = types.map { |type| printable_class(type) }
      raise ArgumentError.new("Error: #{function} expects it's argument to be one of the following types: " + printable_types.join(', '))
    end
  end

  def validate_count_more_than!(function, count, expected)
    if count <= expected
      raise ArgumentError.new("Error: #{function} expects at least #{count} arguments")
    end
  end

  def validate_count!(function, count, expected)
    if count != expected
      raise ArgumentError.new("Error: #{function} expects #{count} arguments")
    end
  end

  def validate_numerics!(function, *values)
    if values.any? { |arg| !arg.is_a? Numeric }
      raise ArgumentError.new("Error: #{function} expects only numeric arguments")
    end
  end

  def printable_class(klass)
    klass.name.split('::').last
  end
end
