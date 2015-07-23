require "json"

class AfixMonitor
  def self.load(file)
    @@file = file
    @@state = JSON.parse(File.read(file)) as Hash(String, JSON::Type)
  end

  def self.int(key)
    @@state.not_nil![key] as Int
  end

  VALUES_I32 = [0, 1, -1] #, 2, -2, 3, -3]

  def self.all_keys
    @@state.not_nil!.keys - ["only"]
  end

  def self.iterate
    keys = @@state.not_nil!["only"]? as Array(JSON::Type)? || @@state.not_nil!.keys
    keys = keys.map { |k| k as String }
    values = keys.map { |k| VALUES_I32.index(self.int(k)).not_nil! }

    c = 1
    values.each_with_index do |v, index|
      if v + c < VALUES_I32.size
        values[index] = v + c
        c = 0
        break
      else
        values[index] = 0
      end
    end

    keys.each_with_index do |k, index|
      @@state.not_nil![k] = VALUES_I32[values[index]].to_i64
    end

    c == 0
  end

  def self.save
    File.write(@@file.not_nil!, @@state.to_json)
  end
end
