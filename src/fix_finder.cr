require "./monitor"

failing_spec = ARGV[0]
spec_filename, spec_line = failing_spec.split(':')
spec_filename = File.expand_path(spec_filename)

afix_cr = spec_filename

afix_bin = "#{afix_cr[0..-4]}"
monitor_file = "#{afix_cr[0..-4]}.afix.json"

def iterate(file)
  AfixMonitor.load(file)
  res = AfixMonitor.iterate
  AfixMonitor.save
  res
end

puts "Running #{afix_cr} using #{monitor_file}"

`crystal build #{afix_cr} --release -o #{afix_bin}`

fixed = false
has_next = true
until fixed || !has_next

  command = "./src/timeout3 -t 1 #{afix_bin} #{monitor_file} -l #{spec_line.to_i+3}" # + 3 due to AfixHeader
  status = Process.run("/bin/sh", input: command, output: false)
  fixed = status.success?

  if fixed
    command = "./src/timeout3 -t 1 #{afix_bin} #{monitor_file}"
    status = Process.run("/bin/sh", input: command, output: false)
    fixed = status.success?
  end


  `pkill -f crystal-run-spec`
  puts "#{File.read(monitor_file)} ... #{fixed}"
  has_next = iterate(monitor_file) unless fixed
end

File.delete(afix_bin)

if fixed
  source = File.read(afix_cr).lines[3..-1].join
  AfixMonitor.load(monitor_file)
  AfixMonitor.all_keys.each do |key|
    v = AfixMonitor.int(key)
    r = if v == 0
      ""
    elsif v < 0
      " - #{-v}"
    else
      " + #{v}"
    end
    source = source.gsub(" + AfixMonitor.int(\"#{key}\")", r)
  end
  source = source.gsub(/ \+ AfixMonitor\.int\(\"[^\"]*\"\)/, "")

  File.write(afix_cr, source)

  puts "Fix found"
else
  puts "No fix found"
end
