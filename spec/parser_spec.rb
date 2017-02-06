require_relative '../src/parser.rb'

RSpec.describe Parser do
  describe '#parse_token' do
    context "integer literals" do
      it "recognizes integer literals" do
        parser = Parser.new code: '42'
        expect(parser.parse_token('42', 0)).to be_an(Integer).and eq(42)
      end

      it "doesn't accept integer with leading 0s" do
        parser = Parser.new code: '042'
        expected_error_message = '''SyntaxError in file  at 1:1: 042
                             ^
Message: "042" cannot be used as a name'''
        expect {parser.parse_token('042', 0) }.to raise_error(Lispetit::SyntaxError, expected_error_message)
      end
    end

    context "float literals" do
      it "recognizes float literals" do
        parser = Parser.new code: '42.3'
        expect(parser.parse_token('42.3', 0)).to be_a(Float).and eq(42.3)
      end

      it "doesn't accept floats with leading 0s" do
        parser = Parser.new code: '042.3'
        expected_error_message = '''SyntaxError in file  at 1:1: 042.3
                             ^
Message: "042.3" cannot be used as a name'''
        expect {parser.parse_token('042.3', 0) }.to raise_error(Lispetit::SyntaxError, expected_error_message)
      end
    end

    context "boolan literals" do
      it "recognizes boolean literals" do
        parser = Parser.new code: 'true'
        expect(parser.parse_token('true', 0)).to eq(true)

        parser = Parser.new code: 'false'
        expect(parser.parse_token('false', 0)).to eq(false)
      end
    end

    context "names" do
      it "recognizes names with snake_case or lisp-case" do
        parser = Parser.new code: 'myfunc'
        expect(parser.parse_token('myfunc', 0)).to be_an_instance_of(ASTName).and have_attributes(value: 'myfunc')

        parser = Parser.new code: 'lisp-case'
        expect(parser.parse_token('lisp-case', 0)).to be_an_instance_of(ASTName).and have_attributes(value: 'lisp-case')

        parser = Parser.new code: '+'
        expect(parser.parse_token('+', 0)).to be_an_instance_of(ASTName).and have_attributes(value: '+')

        parser = Parser.new code: '/'
        expect(parser.parse_token('+', 0)).to be_an_instance_of(ASTName).and have_attributes(value: '+')

        parser = Parser.new code: 'snake_case'
        expect(parser.parse_token('snake_case', 0)).to be_an_instance_of(ASTName).and have_attributes(value: 'snake_case')
      end

      it "forces names to start with a letter unless it's a special case like the + name" do
        parser = Parser.new code: '0invalid'
        expected_error_message = '''SyntaxError in file  at 1:1: 0invalid
                             ^
Message: "0invalid" cannot be used as a name'''
        expect { parser.parse_token('0invalid', 0) }.to raise_error(Lispetit::SyntaxError, expected_error_message)
      end
    end
  end

  describe "#parse" do
    it "creates a root AST node" do
      parser = Parser.new code: ''
      expect(parser.parse).to be_an_instance_of(AST).and have_attributes(children: [])
    end

    it "ignores comments" do
      parser = Parser.new code: '''
42
; these are comments and none of the following are taken into account for the ast
; 43
; (some code)
'''
      ast = parser.parse
      expect(ast).to be_an_instance_of(AST)
      expect(ast.children.count).to eq(1)
      expect(ast.children.first).to be_an(Integer).and eq(42)
    end

    it "can parse S-expressions" do
      parser = Parser.new code: '''
(name1 (name2 name3)
       ((get_func) name4))
'''
      ast = parser.parse
      expect(ast).to be_an_instance_of(AST)
      expect(ast.children.count).to eq(1)
      expect(ast.children.first).to be_an_instance_of(ASTList)
      expect(ast.children.first.children[0]).to be_an_instance_of(ASTName).and have_attributes(value: 'name1')
      expect(ast.children.first.children[1]).to be_an_instance_of(ASTList).and have_attributes(
        children: containing_exactly(
          be_an_instance_of(ASTName).and(have_attributes(value: 'name2')),
          be_an_instance_of(ASTName).and(have_attributes(value: 'name3'))
        )
      )
      expect(ast.children.first.children[2]).to be_an_instance_of(ASTList).and have_attributes(
        children: containing_exactly(
          be_an_instance_of(ASTList).and(have_attributes(children: containing_exactly(
            be_an_instance_of(ASTName).and(have_attributes(value: 'get_func')),
          ))),
          be_an_instance_of(ASTName).and(have_attributes(value: 'name4'))
        )
      )
    end

    it "can parse single line string literals" do
      parser = Parser.new code: '"llama"'
      ast = parser.parse
      expect(ast).to be_an_instance_of(AST)
      expect(ast.children.count).to eq(1)
      expect(ast.children.first).to be_a(String).and eq('llama')
    end
  end
end
