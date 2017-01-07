require_relative 'ast.rb'
require_relative 'errors.rb'

class Parser
  def initialize(file: nil)
    @file = file
    @line = 0
    @column = 0
    @ast = AST.new
  end

  TOKEN_CLASS = /[a-zA-Z0-9._+*\/-]/
  NAME_CLASS = /\A(\+|-|\*|\/|([a-z][a-z_0-9-]*))\z/

  def parse(code = @file.read)
    current_node = @ast
    token = ''
    pos = -1
    loop do
      pos += 1
      break if pos >= code.length
      ch = code[pos]

      if ch == "\n"
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

      # open quote that defines a string
      if ch == '"'
        string_content = ''
        open_quote_pos = @column
        @column += 1
        ch = code[pos += 1]
        until ch == '"'
          if ch.match /\n/
            message = "Reached the end of line without finding a closing quote"
            raise Lispetit::SyntaxError.new message, @file, code, @line, open_quote_pos
          end
          string_content << ch
          @column += 1
          ch = code[pos += 1]
        end
        current_node.add_child ASTString.new(string_content)
        next
      end

      # end of token
      if !token.empty? && !ch.match(TOKEN_CLASS)
        current_node.add_child parse_token(token, code)
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

      # beginning of a list
      if ch == '['
        new_node = ASTList.new
        current_node.add_child new_node
        current_node = new_node
        next
      end

      # end of a list
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

  def parse_token(token, code)
    if token.match /\A(0|[1-9]\d*)\z/ # if integer literal
      ASTInteger.new token.to_i
    elsif token.match /\A(0|[1-9]\d*).(0|[1-9]\d*)\z/ # if float literal
      ASTFloat.new token.to_f
    elsif token == 'true' || token == 'false'
      ASTBoolean.new token == 'true'
    else
      unless token.match NAME_CLASS
        raise Lispetit::SyntaxError.new("#{token} cannot be used as a name", @file, code, @line, @column)
      end
      token
    end
  end

end
