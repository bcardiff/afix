require "json"

def next_combination(list, domain)
  c = 1

  list.each_with_index do |v, index|
    ord_value = domain.index(v).not_nil!
    if ord_value + c < domain.size
      list[index] = domain[ord_value + c]
      c = 0
      break
    else
      list[index] = domain[0]
    end
  end

  c == 0
end

def next_sublist(list, domain)
  start_index = domain.index(list[0]).not_nil!
  size = list.size
  if start_index + list.size < domain.size
    list.clear
    domain[start_index+1..start_index+size].each do |v|
      list << v
    end
    return true
  elsif size < domain.size
    list.clear
    domain[0..size].each do |v|
      list << v
    end
    return true
  else
    return false
  end
end

class AfixMonitor
  def self.load(file)
    @@file = file
    @@state = JSON.parse(File.read(file)) as Hash(String, JSON::Type)
  end

  def self.int(key)
    @@state.not_nil!.fetch(key, 0) as Int
  end

  VALUES_I32 = [0, 1, -1] #, 2, -2, 3, -3]

  def self.all_keys
    @@state.not_nil!.keys - ["only"]
  end

  def self.iterate
    keys = @@state.not_nil!["only"]? as Array(JSON::Type)? || [@@state.not_nil!.keys.first]
    keys = keys.map { |k| k as String }

    values = keys.map { |k| self.int(k).to_i64 }
    has_more = next_combination(values, VALUES_I32.map(&.to_i64) )

    if !has_more
      # ikeys = all_keys.map { |k| keys.includes?(k) }
      has_more = next_sublist(keys, all_keys)
      unless has_more
        return false
      end

      # keys.clear
      all_keys.each_with_index do |k, index|
        # keys << k if ikeys[index]
        @@state.not_nil![k] = 0i64
      end
      @@state.not_nil!["only"] = Array(JSON::Type).new.tap do |arr|
        keys.each { |k| arr << k as JSON::Type }
      end
      return true
    end

    keys.each_with_index do |k, index|
      @@state.not_nil![k] = values[index]
    end

    return has_more
  end

  def self.save
    File.write(@@file.not_nil!, @@state.to_json)
  end
end
