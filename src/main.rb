require 'trollop'

require_relative 'parser.rb'
require_relative 'errors.rb'
require_relative 'eval.rb'
require_relative 'core.rb'
require_relative 'repl.rb'

p = Trollop::Parser.new do
  version "0.0.1"
  banner <<-EOS
lispetit is a small LISP language

Usage:
       lispetit [options] <script> for executing a script
       lispetit -i                 for starting an interactive REPL session
EOS

  opt :interactive, "start an interactive REPL session"
end

opts = Trollop::with_standard_exception_handling p do
  raise Trollop::HelpNeeded if ARGV.empty? # show help screen
  p.parse ARGV
end

if opts[:interactive]
  puts "Welcome to the lispetit REPL..."
  REPL.new.run
  exit
end

if ARGV.length != 1
  puts "You should pass the path to a single script to be executed"
  exit
end

parser = Parser.new(file: File.new(ARGV.first))
begin
  ast = parser.parse
  puts ast
  puts ''
  env = Core.methods_hash
  Eval.eval_sexpr(ast, env, parser.code)
rescue Lispetit::SyntaxError => e
  puts e.message
rescue Lispetit::RuntimeError => e
  puts e.message
end

