require 'readline'

require_relative 'core.rb'
require_relative 'eval.rb'


class REPL
  def initialize
    @env = Core.methods_hash
  end

  def run
    form = ''
    while line = Readline.readline('> ', true)
      form += line + "\n"
      begin
        if sexpr_balance(form) == 0
          ast = Parser.new(code: form).parse
          result = Eval.eval_sexpr(ast.children.first, @env, form)
          puts result
          form = ''
        end
      rescue Lispetit::SyntaxError, Lispetit::RuntimeError => e
        form = ''
        puts e.message
      end
    end

  rescue Interrupt
    puts "\nAdios!"
  end

  private

  def sexpr_balance(code)
    balance = 0
    line = 0
    column = 0
    code.each_char.with_index do |c, i|
      case c
      when '(' then balance += 1
      when ')' then balance -= 1
      when "\n" then line += 1
      end
      if balance < 0
        raise Lispetit::SyntaxError.new('Unexpected closing parenthesis', nil, code, line, column)
      end
      column += 1
    end
    balance
  end
end
