require_relative 'core.rb'

# Defines functions for evaluation of lispetit's ASTs
class Eval
  class << self
    def eval_sexpr(ast_node, env, code)
      case ast_node
      when Numeric, String then ast_node
      when Lispetit::Name
        begin
          env.fetch(ast_node.to_s)
        rescue KeyError
          raise Lispetit::RuntimeError.new("Unknown name '#{ast_node}'",
                                           ast_node.file, code,
                                           ast_node.line, ast_node.column)
        end
      when Lispetit::List
        # If empty S-expr, just return an empty list
        return Lispetit::List.new [] if ast_node.empty?

        return handle_quote(ast_node, code) if ast_node[0].to_s == 'quote'

        return handle_if(ast_node, env, code) if ast_node[0].to_s == 'if'

        return handle_define(ast_node, env, code) if ast_node[0].to_s == 'define'

        return handle_fn(ast_node, env, code) if ast_node[0].to_s == 'fn'

        return handle_macro(ast_node, env, code) if ast_node[0].to_s == 'macro'

        return handle_let(ast_node, env, code) if ast_node[0].to_s == 'let'

        return handle_do(ast_node, env, code) if ast_node[0].to_s == 'do'

        # action can be either a function (or method if defined in Core)
        # or a macro
        action = eval_sexpr(ast_node.first, env, code)

        if action.is_a? Lispetit::Macro
          arguments = ast_node.drop(1).map { |arg| quote(arg) }
          # pass the environment as a block because I don't want to enforce
          # methods in core # to define an argument for the environment if
          # they are not going to use it
          form = action.call(*arguments) { env }
          eval_sexpr(form, env, code)
        elsif action.is_a?(Lispetit::Function) || action.is_a?(Method)
          arguments = ast_node.drop(1).map { |arg| eval_sexpr(arg, env, code) }
          # pass the environment as a block because I don't want to enforce
          # methods in core # to define an argument for the environment if
          # they are not going to use it
          action.call(*arguments) { env }
        else
          # TODO: exception
        end
      else
        if ast_node.instance_of? AST
          # AST node is only the top level list of expressions;
          # We just evaluate them in order
          ast_node.children.each { |node| eval_sexpr quote(node), env, code }
        end
      end
    end

    def handle_quote(ast_node, code)
      if ast_node.count != 2
        error_msg = 'quote expression needs to have 1 argument'
        raise_runtime_err(error_msg, ast_node, code)
      end

      quote(ast_node[1])
    end

    def quote(value)
      case value
      when ASTList then value.to_list
      when ASTName then value.to_name
      # when AST then value.children.map { |c| quote(c) }
      else value
      end
    end

    def handle_if(ast_node, env, code)
      if ast_node.count != 3 && ast_node.count != 4
        error_msg = 'if expression needs to have 2 or 3 arguments '\
                    '(test, consequence and an optional alternative)'
        raise_runtime_err(error_msg, ast_node, code)
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
        error_msg = 'define expression needs 2 arguments (define name value)'
        raise_runtime_err(error_msg, ast_node, code)
      end

      unless ast_node[1].is_a? Lispetit::Name
        error_msg = 'the first argument of define should be a valid name'
        raise_runtime_err(error_msg, ast_node, code)
      end

      value = eval_sexpr(ast_node[2], env, code)
      env[ast_node[1].to_s] = value
    end

    def handle_fn(ast_node, env, code)
      if ast_node.count != 3
        error_msg = 'fn expects two arguments: a parameter list and a body'
        raise_runtime_err(error_msg, ast_node, code)
      end

      unless ast_node[1].is_a? Lispetit::List
        error_msg = 'The parameters for a fn should be a list'
        raise_runtime_err(error_msg, ast_node, code)
      end

      unless ast_node[1].all? { |param| param.is_a? Lispetit::Name }
        error_msg = 'The parameters for a fn should be a list of names'
        raise_runtime_err(error_msg, ast_node, code)
      end

      parameters = ast_node[1].map(&:to_s)
      body = ast_node[2]
      Lispetit::Function.new parameters, body, env, code
    end

    def handle_macro(ast_node, env, code)
      if ast_node.count != 3
        error_msg = 'macro expects two arguments: a parameter list and a body'
        raise_runtime_err(error_msg, ast_node, code)
      end

      unless ast_node[1].is_a? Lispetit::List
        error_msg = 'The parameters for a macro should be a list'
        raise_runtime_err(error_msg, ast_node, code)
      end

      unless ast_node[1].all? { |param| param.is_a? Lispetit::Name }
        error_msg = 'The parameters for a macro should be a list of names'
        raise_runtime_err(error_msg, ast_node, code)
      end

      parameters = ast_node[1].map(&:to_s)
      body = ast_node[2]
      Lispetit::Macro.new parameters, body, env, code
    end

    # TODO: fix this
    def handle_let(ast_node, env, code)
      normalized_arguments = ast_node[1].each_with_index.map do |x, i|
        i.even? ? x.to_s : x
      end

      definitions = Hash[*normalized_arguments]
      local_env = env.clone
      definitions.each_pair do |name, value|
        local_env[name] = eval_sexpr(value, local_env, code)
      end
      eval_sexpr(ast_node[2], local_env, code)
    end

    def handle_do(ast_node, env, code)
      ast_node.drop(1).map { |arg| eval_sexpr(arg, env, code) }.last
    end

    private

    def raise_runtime_err(msg, ast_node, code)
      raise Lispetit::RuntimeError.new(msg, ast_node[0].file,
                                       code, ast_node[0].line,
                                       ast_node[0].column)
    end
  end
end
