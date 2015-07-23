require "./monitor"

afix_cr = ARGV[0]
monitor_file = "#{afix_cr[0..-4]}.json"

def iterate(file)
  AfixMonitor.load(file)
  AfixMonitor.iterate
  AfixMonitor.save
end

puts "Running #{afix_cr} using #{monitor_file}"

fixed = false
until fixed
  command = "./src/timeout3 -t 3 crystal spec #{afix_cr} #{monitor_file}"
  status = Process.run("/bin/sh", input: command, output: false)
  fixed = status.success?
  puts "#{File.read(monitor_file)} ... #{fixed}"
  iterate(monitor_file)
end
