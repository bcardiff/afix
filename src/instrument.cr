require "json"
require "compiler/crystal/**"

include Crystal

def append_to_line(filename, line, code)
  source = File.read(filename)
  File.open(filename, "w") do |file|
    source.lines.each_with_index do |line_code, index|
      if index + 1 == line
        file.print("#{line_code.chop}#{code}\n")
      else
        file.print(line_code)
      end
    end
  end
end

class AssignIntrumentor < Visitor
  getter sample_monitor

  def initialize(@filename, @output_filename)
    @patched_location = Set(String).new
    @next_var_monitor = 0
    @sample_monitor = Hash(String, JSON::Type).new
  end

  def process(result : Compiler::Result)
    result.program.def_instances.each_value do |typed_def|
      typed_def.accept(self)
    end

    result.node.accept(self)
  end

  def visit(node : Call)
    if target_defs = node.target_defs
      target_defs.each do |target_def|
        can_instrument?(target_def) do |loc|
          target_def.accept(self)
        end
      end
    end

    true
  end

  def visit(node : Assign)
    can_instrument?(node) do |loc|
      t = node.type?
      if t.is_a?(IntegerType)
        if t.kind == :i32
          append_to_line(@output_filename, loc.line_number, " + AfixMonitor.int(\"#{fresh_monitor(:i)}\")")
          @patched_location << loc.to_s
        end
      end
    end
    false
  end

  def visit(node)
    true
  end

  def can_instrument?(node)
    if loc = node.location
      if loc.filename == @filename && !@patched_location.includes?(loc.to_s)
        yield loc
      end
    end
  end

  def fresh_monitor(prefix)
    @next_var_monitor+=1
    key = "#{prefix}#{@next_var_monitor.to_s(32)}"
    @sample_monitor[key] = 0i64
    key
  end

end

filename = File.expand_path(ARGV[0])
source = Compiler::Source.new(filename, File.read(filename))

output = filename[0..-4] + ".afix.cr"
File.write(output, source.code)

compiler = Compiler.new
compiler.no_build = true
result = compiler.compile(source, "fake-no-build")
visitor = AssignIntrumentor.new(filename, output)
visitor.process(result)

monitor_sample = filename[0..-4] + ".afix.json"
File.write(monitor_sample, visitor.sample_monitor.to_json)

File.write(output, %(require "../src/monitor"
AfixMonitor.load(ARGV[0])

#{File.read(output)}
))
