require_relative 'types.rb'

class AST
  @@next_id = 0

  attr_reader :children, :id, :file, :line, :column
  attr_accessor :parent

  def initialize(file = nil, line = nil, column = nil)
    @id = @@next_id
    @@next_id += 1
    @children = []
    @file = file
    @line = line
    @column = column
  end

  def add_child(child)
    children << child
    if child.is_a? AST
      child.parent = self
    end
  end

  def to_s
    a = "<#{self.class} id=#{@id} parent=#{@parent&.id} children="
    @children[0...-1].each do |c|
      a += "\n" + "\t".ljust(depth+1, "\t") + c.to_s + "> "
    end
    a += "\n" + "\t".ljust(depth+1, "\t") + @children[-1].to_s  unless children.empty?
    a += ">"
  end

  protected

  def depth
    return 0 unless @parent
    1 + @parent.depth
  end
 end

class ASTList < AST
  def to_list
    array = children.map do |child|
      case child
        when ASTName then child.to_name
        when ASTList then child.to_list
        else child
      end
    end
    Lispetit::List.new array
  end
end

class ASTName < AST
  attr_accessor :value

  def initialize(value, file = nil, line = nil, column = nil)
    super(file, line, column)
    @value = value
  end

  def to_s
    "<#{self.class.to_s} #{@value}"
  end

  def to_name
    Lispetit::Name.new @value, file = @file, line = @line, column = @column
  end
end
