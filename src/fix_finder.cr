require "./monitor"

afix_cr = ARGV[0]
afix_bin = "#{afix_cr[0..-4]}"
monitor_file = "#{afix_cr[0..-4]}.json"

def iterate(file)
  AfixMonitor.load(file)
  res = AfixMonitor.iterate
  AfixMonitor.save
  res
end

puts "Running #{afix_cr} using #{monitor_file}"

`crystal build #{afix_cr} -o #{afix_bin}`

fixed = false
has_next = true
until fixed || !has_next
  command = "./src/timeout3 -t 1 #{afix_bin} #{monitor_file}"
  status = Process.run("/bin/sh", input: command, output: false)
  fixed = status.success?
  `pkill -f crystal-run-spec`
  puts "#{File.read(monitor_file)} ... #{fixed}"
  has_next = iterate(monitor_file) unless fixed
end

if fixed
  original_cr = "#{afix_cr[0..-9]}.cr"
  fixed_file = "#{afix_cr[0..-9]}.patched.cr"

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

  File.write(fixed_file, source)

  `diff -u #{original_cr} #{fixed_file} > #{original_cr}.patch`

  puts "Fix found"
else
  puts "No fix found"
end
