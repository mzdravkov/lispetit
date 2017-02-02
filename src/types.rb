module Lispetit
  class List < Array
    def initialize(array, file = nil, line = nil, column = nil)
      super(array)
      @file = file
      @line = line
      @column = column
    end

    def to_s
      str = "("
      str += each { |elem| elem.to_s }.join(" ")
      str += ")"
    end
  end

  class Name
    attr_reader :file, :line, :column

    def initialize(name, file = nil, line = nil, column = nil)
      @name = name
      @file = file
      @line = line
      @column = column
    end

    def to_s
      @name
    end
  end
end
