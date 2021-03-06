require_relative 'ast.rb'
require_relative 'errors.rb'

# A class that takes a file or a string with code and creates an AST out of it
class Parser
  attr_reader :code

  def initialize(file: nil, code: nil)
    @file = file
    @code = code
    if @code.nil?
      if @file.nil?
        message = 'Can\'t create a parser without given file or code string'
        throw Exception.new message
      end
      @code = @file.read
    end
    @line = 0
    @column = -1
    @ast = AST.new
  end

  TOKEN_CLASS = %r{[a-zA-Z0-9._+&*/\-?<>=]}
  NAME_CLASS = %r{\A(\+|-|\*|/|&|<=?|>=?|([a-z][a-z_0-9*/\<\>\=+-]*\??))\z}

  def parse
    current_node = @ast
    token = ''
    token_start_pos = nil
    pos = -1
    loop do
      pos += 1
      break if pos >= code.length
      ch = code[pos]

      # end of token
      if !token.empty? && !ch.match(TOKEN_CLASS)
        current_node.add_child parse_token(token, token_start_pos)
        token = ''
      end

      if ch == "\n"
        @line += 1
        @column = 0
        next
      else
        @column += 1
      end

      # if comment
      if ch == ';'
        ch = code[pos += 1] until ch =~ /\n/
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
          if ch =~ /\n/
            message = 'Reached the end of line without finding a closing quote'
            raise Lispetit::SyntaxError.new message, @file, code,
                                            @line, open_quote_pos
          end
          string_content << ch
          @column += 1
          ch = code[pos += 1]
        end
        # current_node.add_child ASTString.new(string_content)
        current_node.add_child string_content
        next
      end

      if ch == '('
        new_node = ASTList.new(@file, @line, @column)
        current_node.add_child new_node
        current_node = new_node
        next
      end

      if ch == ')'
        current_node = current_node.parent
        next
      end

      if ch.match TOKEN_CLASS
        token_start_pos = @column if token.empty?
        token += ch
        next
      end
    end

    @ast
  end

  def parse_token(token, token_start_pos)
    integer_regex = /\A-?(0|([1-9]\d*))\z/
    float_regex = /\A-?(0|[1-9]\d*)\.(0|[1-9]\d*)\z/
    case token
    when integer_regex then token.to_i
    when float_regex then token.to_f
    when 'true', 'false' then token == 'true'
    when 'nil' then token.nil?
    else
      unless token =~ NAME_CLASS
        raise Lispetit::SyntaxError.new("\"#{token}\" cannot be used as a name",
                                        @file, @code, @line, token_start_pos)
      end
      ASTName.new token, @file, @line, token_start_pos
    end
  end
end
