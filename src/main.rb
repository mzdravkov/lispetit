require 'trollop'

require_relative 'parser.rb'

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
  puts "Start REPL..."
  exit
end

if ARGV.length != 1
  puts "You should pass the path to a single script to be executed"
  exit
end

puts "Execute script..."
parser = Parser.new
puts parser.parse(File.read(ARGV.first))
