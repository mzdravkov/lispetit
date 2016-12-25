class AST
  @@next_id = 0

  attr_reader :children, :id
  attr_accessor :parent

  def initialize
    @id = @@next_id
    @@next_id += 1
    @children = []
  end

  def add_child(child)
    children << child
    if child.is_a? AST
      child.parent = self
    end
  end

  def to_s
    a = "<#{self.class} id=#{@id} parent=#{@parent&.id} children="
    @children.each do |c|
      a += "\n" + "\t".ljust(depth+1, "\t") + c.to_s + " "
    end
    a += ">"
  end

  protected

  def depth
    return 0 unless @parent
    1 + @parent.depth
  end
 end

class ASTList < AST
end
