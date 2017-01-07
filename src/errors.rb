
module Lispetit
  class SyntaxError < SyntaxError
    def initialize(message, file, code, line, column)
      beginning_of_message = "SyntaxError in file #{file&.path} at #{line + 1}:#{column}: "
      space_before_pointer = ' '.ljust(beginning_of_message.length + column - 1)
      error_message = beginning_of_message + code.lines[line] + "\n" +
                      space_before_pointer + "^" + "\n" +
                      "Message: #{message}"
      super(error_message)
    end
  end

  # class RuntimeError < SyntaxError
  #   def initialize(message, code, line, column)
  #     beginning_of_message = "SyntaxError at #{line + 1}:#{column}: "
  #     space_before_pointer = ' '.ljust(beginning_of_message.length + column - 1)
  #     error_message = beginning_of_message + code.lines[line] + "\n" +
  #                     space_before_pointer + "^" + "\n" +
  #                     "Message: #{message}"
  #     super(error_message)
  #   end
  # end
end
