require "spec"
require "yaml"
require "compiler/crystal/**"

include Crystal

def gather_sources(filenames)
  filenames.map do |filename|
    unless File.file?(filename)
      raise "File #{filename} does not exist"
    end
    filename = File.expand_path(filename)
    Compiler::Source.new(filename, File.read(filename))
  end
end

class AssignIntrumentor < Visitor

  def initialize(@filename)
    @patched_location = Set(String).new
  end

  def process(result : Compiler::Result)
    result.program.def_instances.each_value do |typed_def|
      typed_def.accept(self)
    end

    result.node.accept(self)
  end

  def visit(node : Assign)
    if loc = node.location
      if loc.filename == @filename && !@patched_location.includes?(loc.to_s)
        @patched_location << loc.to_s
        t = node.type
        if t.is_a?(IntegerType) && t.kind == :i32
          pp node
        end
      end
    end
  end

  def visit(node)
    true
  end

end

filename = File.expand_path(ARGV[0])

compiler = Compiler.new
compiler.no_build = true
result = compiler.compile(gather_sources([filename]), "fake-no-build")
AssignIntrumentor.new(filename).process(result)

