module Core
  extend Core

  def print(*arguments)
    Kernel.print *arguments
  end

  def println(*arguments)
    Kernel.print *arguments
    puts "\n"
  end

  def +(*arguments)
    validate_numerics :+, arguments

    arguments.reduce(&:+)
  end

  def *(*arguments)
    validate_numerics :*, arguments

    arguments.reduce(&:*)
  end

  def methods_hash
    Hash[instance_methods.map { |m| [m.to_s, method(m)] }]
  end

  private

  def validate_numerics(function, *values)
    if values.any? { |arg| !arg.is_a? Numeric }
      #TODO: throw error
    end
  end
end
