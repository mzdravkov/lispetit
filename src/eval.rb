require_relative "core.rb"

class Eval
  def eval_sexpr(ast_node, scope)
    # if ast_node.is_a? ASTList
    #   return ast_node.map { |child| eval_sexpr child }.to_a
    # end

    if ast_node.is_a? ASTNumeric
      ast_node.value
    elsif ast_node.is_a? ASTBoolean
      ast_node.value
    elsif ast_node.is_a? ASTString
      ast_node.value
    elsif ast_node.is_a? ASTList
      ast_node.map { |child| eval_sexpr child }.to_a
    else
      if ast_node.children.empty?
        # Empty S-expr, just do nothing
        return
        # throw Exception.new "Can't have an empty S-expression"
      end
      function = ast_node.children.first
      arguments = ast_node.children.drop(1).map { |arg| eval_sexpr(arg) }
      eval_function(function, arguments)
    end
  end

  def eval_function(name, arguments, scope)
    if Core.methods(false).include? name.to_sym
      Core.send name, *arguments
    else
    end
  end
end
