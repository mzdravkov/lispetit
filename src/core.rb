require_relative 'types.rb'
require_relative 'eval.rb'

# Defines the core functions of the language
# Note: Few of the most basic functions are handled by Eval directly
# Note: There's also the file core.lip in the same directory. Some
#       of the core functions are defined there in lispetit.
module Core
  extend Core
  include Lispetit

  def type(argument)
    argument.class
  end

  def print(*arguments)
    Kernel.print(*arguments)
  end

  def println(*arguments)
    Kernel.print(*arguments)
    puts "\n"
  end

  def list(*arguments)
    List.new arguments
  end

  # TODO: finish with this method
  def macroexpand(argument)
    if argument.is_a? List
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

  def >(*arguments)
    arguments.reduce do |a, b|
      return false unless a > b
      b
    end
    true
  end

  def >=(*arguments)
    arguments.reduce do |a, b|
      return false unless a >= b
      b
    end
    true
  end

  def <(*arguments)
    arguments.reduce do |a, b|
      return false unless a < b
      b
    end
    true
  end

  def <=(*arguments)
    arguments.reduce do |a, b|
      return false unless a <= b
      b
    end
    true
  end

  def not(argument)
    return true if argument == false || argument.nil?
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
    base**degree
  end

  def call(object, method, *arguments)
    result = object.public_send(method, *arguments)
    return List.new(result) if result.is_a? Array
    result
  end

  def len(coll)
    validate_type_is_one_of!(:len, coll, List, String)
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

  def string?(argument)
    argument.is_a? String
  end

  def trim(string)
    string.strip
  end

  def empty?(coll)
    coll.empty?
  end

  def nil?(argument)
    argument.nil?
  end

  def first(list)
    list.first
  end

  def rest(list)
    List.new list.drop(1)
  end

  def drop(n, list)
    List.new list.drop(n)
  end

  def take(n, list)
    List.new list.take(n)
  end

  def last(list)
    list.last
  end

  def reverse(coll)
    coll.reverse
  end

  def concat(*colls)
    colls.reduce(&:+)
  end

  def map(fn, *colls)
    results = []
    loop do
      args = colls.reject(&:empty?).map { |coll| coll.delete_at 0 }
      return List.new(results) if args.count < colls.count
      env = yield
      results << fn.call(*args) { env }
    end
  end

  def filter(fn, coll)
    env = yield
    List.new coll.select { |elem| fn.call(elem) { env } }
  end

  def reduce(fn, coll, initial = :unset)
    env = yield
    if initial == :unset
      coll.reduce { |aggregate, elem| fn.call(aggregate, elem) { env } }
    else
      coll.reduce(initial) { |aggregate, e| fn.call(aggregate, e) { env } }
    end
  end

  def apply(fn, coll)
    fn.call(*coll)
  end

  def repeat(times, value)
    List.new Array.new(times, value)
  end

  def range(from, to, step = 1)
    List.new (from..to).step(step).to_a

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
        error_msg = "Error: #{function} expects argument "\
                    "'#{arg}' to be #{printable_class(expected)}"
        raise ArgumentError, error_msg
      end
    end
  end

  def validate_type_is_one_of!(function, argument, *types)
    return if types.include?(argument.class)
    printable_types = types.map { |type| printable_class(type) }
    error_msg = "Error: #{function} expects it's argument to be one "\
                'of the following types: ' + printable_types.join(', ')
    raise ArgumentError, error_msg
  end

  def validate_count_more_than!(func, count, expected)
    return if count > expected
    raise ArgumentError, "Error: #{func} expects at least #{count} arguments"
  end

  def validate_count!(function, count, expected)
    return if count == expected
    raise ArgumentError, "Error: #{function} expects #{count} arguments"
  end

  def validate_numerics!(function, values)
    if values.any? { |arg| !arg.is_a? Numeric }
      p values
      raise ArgumentError, "Error: #{function} expects only numeric arguments"
    end
  end

  def printable_class(klass)
    klass.name.split('::').last
  end
end
