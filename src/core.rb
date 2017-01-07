module Core
  # def self.define(name, arguments, body)

  def self.+(*arguments)
    if arguments.any? { |arg| !arg.is_a? Numeric }
      #TODO: throw error
    end

    arguments.reduce(&:+)
  end
end
