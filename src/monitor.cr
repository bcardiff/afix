require "json"

class AfixMonitor
  def self.load(file)
    @@file = file
    @@state = JSON.parse(File.read(file)) as Hash(String, JSON::Type)
  end

  def self.int(key)
    @@state.not_nil![key] as Int
  end

  VALUES_I32 = [0, 1, -1, 2, -2, 3, -3]

  def self.iterate
    k = @@state.not_nil!.keys.first
    v = self.int(k)
    @@state.not_nil![k] = if v > 0
      -v
    else
      -v + 1
    end
  end

  def self.save
    File.write(@@file.not_nil!, @@state.to_json)
  end
end
