require_relative "core.rb"

class Eval
  class Function
    attr_accessor :name, :parameters, :body, :env

    def initialize(parameters, body, env, code)
      @parameters = parameters
      @body = body
      @env = env
      @code = code
    end

    def to_s
      "<Function #{object_id}>"
    end

    def call(*arguments)
      # join the paramaters and their actual values
      args = Hash[@parameters.zip(arguments)]
      # merge the def-env (the closure) with the call-env and the args
      actual_env = @env.merge(yield).merge(args)

      Eval.eval_sexpr(@body, actual_env, @code)
    end
  end

  class Macro < Function
    def to_s
      "<Macro #{object_id}>"
    end
  end

  def self.eval_sexpr(ast_node, env, code)
    case ast_node
    when Numeric, String then ast_node
    when Lispetit::Name
      begin
        env.fetch(ast_node.to_s)
      rescue KeyError
        raise Lispetit::RuntimeError.new("Unknown name '#{ast_node}'", ast_node.file, code, ast_node.line, ast_node.column)
      end
    when Lispetit::List
      # If empty S-expr, just return an empty list
      return Lispetit::List.new [] if ast_node.empty?

      return handle_quote(ast_node, code) if ast_node[0].to_s == 'quote'

      return handle_if(ast_node, env, code) if ast_node[0].to_s == 'if'

      return handle_define(ast_node, env, code) if ast_node[0].to_s == 'define'

      return handle_fn(ast_node, env, code) if ast_node[0].to_s == 'fn'

      return handle_macro(ast_node, env, code) if ast_node[0].to_s == 'macro'

      # action can be either a function (or method if defined in Core) or a macro
      action = eval_sexpr(ast_node.first, env, code)

      if action.is_a? Macro
        arguments = ast_node.drop(1).map { |arg| quote(arg) }
        # pass the environment as a block because I don't want to enforce methods in core
        # to define an argument for the environment if they are not going to use it
        form = action.call(*arguments) { env }
        eval_sexpr(form, env, code)
      elsif action.is_a?(Function) || action.is_a?(Method)
        arguments = ast_node.drop(1).map { |arg| eval_sexpr(arg, env, code) }
        # pass the environment as a block because I don't want to enforce methods in core
        # to define an argument for the environment if they are not going to use it
        action.call(*arguments) { env }
      else
        #TODO: exception
      end
    when AST # AST node is only the top level list of expressions; We just evaluate them in order
      ast_node.children.each { |node| eval_sexpr node, env, code }
    end
  end

  private

  class << self
    def handle_quote(ast_node, code)
      if ast_node.count != 2
        raise Lispetit::RuntimeError.new("quote expression needs to have 1 argument", ast_node[0].file, code, ast_node[0].line, ast_node[0].column)
      end

      quote(ast_node[1])
    end

    def quote(value)
      case value
      when ASTList then value.to_list
      when ASTName then value.to_name
      else value
      end
    end

    def handle_if(ast_node, env, code)
      if ast_node.count != 3 && ast_node.count != 4
        raise Lispetit::RuntimeError.new("if expression needs to have 2 or 3 arguments (test, consequence and an optional alternative)", ast_node[0].file, code, ast_node[0].line, ast_node[0].column)
      end

      _, test, consequence, alternative = ast_node

      if eval_sexpr(test, env, code)
        eval_sexpr(consequence, env, code)
      else
        eval_sexpr(alternative, env, code)
      end
    end

    def handle_define(ast_node, env, code)
      if ast_node.count != 3
        raise Lispetit::RuntimeError.new("define expression needs to have 2 arguments (define name value)", ast_node[0].file, code, ast_node[0].line, ast_node[0].column)
      end

      unless ast_node[1].is_a? Lispetit::Name
        raise Lispetit::RuntimeError.new("the first argument of define should be a valid name", ast_node[0].file, code, ast_node[0].line, ast_node[0].column)
      end

      value = eval_sexpr(ast_node[2], env, code)
      env.merge! ast_node[1].to_s => value
      value
    end

    def handle_fn(ast_node, env, code)
      if ast_node.count != 3
        raise Lispetit::RuntimeError.new("fn expects two arguments: a parameter list and a body",
                                         ast_node[0].file, code, ast_node[0].line, ast_node[0].column)
      end

      unless ast_node[1].is_a? Lispetit::List
        raise Lispetit::RuntimeError.new("The parameters for a fn should be a list",
                                         ast_node[0].file, code, ast_node[0].line, ast_node[0].column)
      end

      unless ast_node[1].all? { |param| param.is_a? Lispetit::Name }
        raise Lispetit::RuntimeError.new("The parameters for a fn should be a list of names",
                                         ast_node[0].file, code, ast_node[0].line, ast_node[0].column)
      end

      parameters = ast_node[1].map(&:to_s)
      body = ast_node[2]
      Function.new parameters, body, env, code
    end

    def handle_macro(ast_node, env, code)
      if ast_node.count != 3
        raise Lispetit::RuntimeError.new("macro expects two arguments: a parameter list and a body",
                                         ast_node[0].file, code, ast_node[0].line, ast_node[0].column)
      end

      unless ast_node[1].is_a? Lispetit::List
        raise Lispetit::RuntimeError.new("The parameters for a macro should be a list",
                                         ast_node[0].file, code, ast_node[0].line, ast_node[0].column)
      end

      unless ast_node[1].all? { |param| param.is_a? Lispetit::Name }
        raise Lispetit::RuntimeError.new("The parameters for a macro should be a list of names",
                                         ast_node[0].file, code, ast_node[0].line, ast_node[0].column)
      end

      parameters = ast_node[1].map(&:to_s)
      body = ast_node[2]
      Macro.new parameters, body, env, code
    end
  end
end
