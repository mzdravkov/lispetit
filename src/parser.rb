require_relative 'ast.rb'

class Parser
  def initialize
    @line = 0
    @column = 0
    @ast = AST.new
  end

  TOKEN_CLASS = /[a-zA-Z0-9._+*\/-]/
  NAME_CLASS = /\A(\+|-|\*|\/|([a-z][a-z_0-9-]*))\z/

  def parse(code)
    current_node = @ast
    token = ''
    pos = -1
    loop do
      pos += 1
      break if pos >= code.length
      ch = code[pos]

      if ch == '\n'
        @line += 1
        @column = 0
        next
      else
        @column += 1
      end

      # if comment
      if ch == ';'
        ch = code[pos += 1] until ch.match /\n/
        @line += 1
        @column = 0
      end

      # end of token
      if !token.empty? && !ch.match(TOKEN_CLASS)
        current_node.add_child parse_token(token)
        token = ''
      end

      if ch == '('
        new_node = AST.new
        current_node.add_child new_node
        current_node = new_node
        next
      end

      if ch == ')'
        current_node = current_node.parent
        next
      end

      if ch == '['
        new_node = ASTList.new
        current_node.add_child new_node
        current_node = new_node
        next
      end

      if ch == ']'
        current_node = current_node.parent
        next
      end

      if ch.match TOKEN_CLASS
        token += ch
        next
      end
    end

    @ast
  end

  def parse_token(token)
    if token.match /\A(0|[1-9]\d*)\z/ # if integer literal
      ASTInteger.new token.to_i
    elsif token.match /\A(0|[1-9]\d*).(0|[1-9]\d*)\z/ # if float literal
      ASTFloat.new token.to_f
    else
      unless token.match NAME_CLASS
        # TODO: create custom exception class that will hold the (file, line, column) info
        throw Exception.new("#{token} cannot be used as a name")
      end
      token
    end
  end
end
