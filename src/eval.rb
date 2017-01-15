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

  def self.eval_sexpr(ast_node, env, code)
    case ast_node
    when Numeric then ast_node
    when String then ast_node
    when ASTName
      begin
        env.fetch(ast_node.value)
      rescue KeyError
        raise Lispetit::RuntimeError.new("Unknown name '#{ast_node.value}'", ast_node.file, code, ast_node.line, ast_node.column)
      end
    when ASTList
      # If empty S-expr, just return an empty list
      return Lispetit::List.new [] if ast_node.children.empty?

      return handle_quote(ast_node, code) if ast_node.children[0].value == 'quote'

      return handle_if(ast_node, env, code) if ast_node.children[0].value == 'if'

      return handle_define(ast_node, env, code) if ast_node.children[0].value == 'define'

      return handle_fn(ast_node, env, code) if ast_node.children[0].value == 'fn'

      function = eval_sexpr(ast_node.children.first, env, code)
      arguments = ast_node.children.drop(1).map { |arg| eval_sexpr(arg, env, code) }
      # pass the environment as a block because I don't want to enforce methods in core
      # to define an argument for the environment if they are not going to use it
      function.call(*arguments) { env }
    when AST
      ast_node.children.each { |node| eval_sexpr node, env, code }
    end
  end

  private

  class << self
    def handle_quote(ast_node, code)
      if ast_node.children.count != 2
        raise Lispetit::RuntimeError.new("quote expression needs to have 1 argument", ast_node.file, code, ast_node.line, ast_node.column)
      end

      value = ast_node.children[1]
      case value
      when ASTList then value.to_list
      when ASTName then value.to_name
      else value
      end
    end

    def handle_if(ast_node, env, code)
      if ast_node.children.count != 3 && ast_node.children.count != 4
        raise Lispetit::RuntimeError.new("if expression needs to have 2 or 3 arguments (test, consequence and an optional alternative)", ast_node.file, code, ast_node.line, ast_node.column)
      end

      _, test, consequence, alternative = ast_node.children

      if eval_sexpr(test, env, code)
        eval_sexpr(consequence, env, code)
      else
        eval_sexpr(alternative, env, code)
      end
    end

    def handle_define(ast_node, env, code)
      if ast_node.children.count != 3
        raise Lispetit::RuntimeError.new("define expression needs to have 2 arguments (define name value)", ast_node.file, code, ast_node.line, ast_node.column)
      end

      value = eval_sexpr(ast_node.children[2], env, code)
      env.merge! ast_node.children[1].value => value
      value
    end

    def handle_fn(ast_node, env, code)
      children = ast_node.children

      if children.count != 3
        raise Lispetit::RuntimeError.new("fn expects two arguments: a parameter list and a body",
                                         ast_node.file, code, ast_node.line, ast_node.column)
      end

      unless children[1].is_a? ASTList
        raise Lispetit::RuntimeError.new("The parameters for a fn should be a list",
                                         ast_node.file, code, ast_node.line, ast_node.column)
      end

      unless children[1].children.all? { |param| param.is_a? ASTName }
        raise Lispetit::RuntimeError.new("The parameters for a fn should be a list of names",
                                         ast_node.file, code, ast_node.line, ast_node.column)
      end

      Function.new children[1].children.map(&:value), children[2], env, code
    end
  end
end
