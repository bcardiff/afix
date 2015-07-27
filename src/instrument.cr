require "json"
require "compiler/crystal/**"
require "./reach"

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

  def initialize(@filename)
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
          append_to_line(loc.filename as String, loc.line_number, " + AfixMonitor.int(\"#{fresh_monitor(:i)}\")")
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


# get the main entry file (spec) and failing test
failing_spec = ARGV[0]
spec_filename, spec_line = failing_spec.split(':')
spec_filename = File.expand_path(spec_filename)
source = Compiler::Source.new(spec_filename, File.read(spec_filename))

# compile without build
compiler = Compiler.new
compiler.no_build = true
result = compiler.compile(source, "fake-no-build")

# find the failing test call
spec_it_finder = SpecCallFinder.new(spec_filename, spec_line.to_i)
spec_it_finder.process(result)

# instrument reachable code from failing test call
visitor = AssignIntrumentor.new(spec_filename)
spec_it_finder.calls.each do |call|
  call.accept(visitor)
end

# save initial monitor
monitor_sample = spec_filename[0..-4] + ".afix.json"
File.write(monitor_sample, visitor.sample_monitor.to_json)

# save in main entry file, required code to run monitor
File.write(spec_filename, %(require "../src/monitor"
AfixMonitor.load(ARGV[0])

#{File.read(spec_filename)}
))
