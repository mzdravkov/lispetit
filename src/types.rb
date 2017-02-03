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
      content = map do |e|
        case e
        when String then '"' + e + '"'
        when NilClass then "nil"
        else e
        end
      end
      str += content.join(" ")
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
