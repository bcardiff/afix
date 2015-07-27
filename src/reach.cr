require "compiler/crystal/**"

include Crystal

class SpecCallFinder < Visitor
  getter calls

  def initialize(@filename, @line)
    @calls = [] of Call
  end

  def process(result : Compiler::Result)
    result.program.def_instances.each_value do |typed_def|
      typed_def.accept(self)
    end

    result.node.accept(self)
  end

  def visit(node : Call)
    if can_instrument?(node)
      if node.location.not_nil!.line_number == @line
        @calls << node
      end
      true
    else
      false
    end
  end

  def visit(node : Expressions | Block)
    true
  end

  def visit(node)
    can_instrument?(node)
  end

  def can_instrument?(node)
    if loc = node.location
      if loc.filename == @filename
        return true
      end
    end

    false
  end

end

# failing_spec = ARGV[0]
# spec_filename, spec_line = failing_spec.split(':')
# spec_filename = File.expand_path(spec_filename)
# source = Compiler::Source.new(spec_filename, File.read(spec_filename))

# compiler = Compiler.new
# compiler.no_build = true
# result = compiler.compile(source, "fake-no-build")
# visitor = SpecCallFinder.new(spec_filename, spec_line.to_i)
# visitor.process(result)
