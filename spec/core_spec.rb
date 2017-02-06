require_relative '../src/core.rb'
require_relative '../src/types.rb'

RSpec.describe Core do
  describe "::print" do
    it "prints simple literals" do
      expect { Core.print 42 }.to output("42").to_stdout
      expect { Core.print 42.3 }.to output("42.3").to_stdout
      expect { Core.print "llama" }.to output("llama").to_stdout
    end

    it "prints a list nicely" do
      list = Lispetit::List.new [1, 2.3, "llama"]
      expect { Core.print list  }.to output('(1 2.3 "llama")').to_stdout
    end

    it "prints nested lists" do
      list = Lispetit::List.new [1, Lispetit::List.new([2.3, "llama"])]
      expect { Core.print list  }.to output('(1 (2.3 "llama"))').to_stdout
    end
  end

  describe "::+" do
    it "returns the argument if only one argument is given" do
      expect(Core.+ 1).to eq(1)
    end

    it "sums an arbitrary number of arguments" do
      expect(Core.+ 1, 2, 3, 4, 5, 6).to eq(21)
    end
  end

  describe "::-" do
    it "subtracts an arbitrary number of arguments" do
      expect(Core.- 1, 2, 3, 4, 5, 6).to eq(-19)
    end
  end

  describe "::*" do
    it "multiplies an arbitrary number of arguments" do
      expect(Core.* 1, 2, 3, 4).to eq(24)
    end
  end

  describe "::/" do
    it "divides the first argument by all others" do
      expect(Core./ 1).to eq(1)
      expect(Core./ 18, 2, 3).to eq(3)
    end
  end
end
