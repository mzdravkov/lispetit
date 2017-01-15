module Lispetit
  class List
    def initialize(array)
      @array = array
    end

    def to_s
      str = "("
      str += @array.each { |child| child.to_s }.join(" ")
      str += ")"
    end
  end

  class Name
    def initialize(name)
      @name = name
    end

    def to_s
      @name
    end
  end
end
