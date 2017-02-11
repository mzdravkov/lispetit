module Lispetit
  # An extension of Ruby's Array that will be used to represent
  # strings in lispetit
  class List < Array
    def initialize(array, file = nil, line = nil, column = nil)
      super(array)
      @file = file
      @line = line
      @column = column
    end

    def to_s
      str = '('
      content = map do |e|
        case e
        when String then '"' + e + '"'
        when NilClass then 'nil'
        else e.to_s
        end
      end
      str += content.join(' ')
      str + ')'
    end
  end

  # We use this class to store names, so that we can have
  # metadata like the position where a name was used.
  # This is for improving the error messages.
  class Name
    attr_reader :file, :line, :column

    def initialize(name, file = nil, line = nil, column = nil)
      @name = name
      @file = file
      @line = line
      @column = column
    end

    def to_s
      @name
    end
  end

  # a class for lispetit functions
  class Function
    attr_accessor :name, :parameters, :body, :env

    def initialize(parameters, body, env, code)
      if parameters.include? '&'
        if parameters.reverse.take_while { |param| param == '&' }.count > 1
          error_msg = 'Cannot have more than one parameter after the "&"'\
                      'symbol inside function\'s parameter list'
          raise Lispetit::SyntaxError.new(error_msg, nil, @code, nil, nil)
        end
      end
      @parameters = parameters
      @body = body
      @env = env
      @code = code
    end

    def to_s
      "<Function #{object_id}>"
    end

    def call(*arguments)
      args = if @parameters.include? '&'
               # find all parameters before the &
               params_before = @parameters[0...-2]
               # get the parameter name for the rest list
               rest_parameter = @parameters.last
               # merge parameters and their arguments (without the rest)
               args = Hash[params_before.zip(arguments)]
               # add the rest arguments
               args[rest_parameter] = arguments.drop(params_before.count)
             else
               # join the paramaters and their actual values
               Hash[@parameters.zip(arguments)]
             end

      # merge the def-env (the closure) with the call-env and the args
      actual_env = @env.merge(yield).merge(args)

      Eval.eval_sexpr(@body, actual_env, @code)
    end
  end

  # macros are like functions, but eval handles them a little bit different
  class Macro < Function
    def to_s
      "<Macro #{object_id}>"
    end
  end
end
