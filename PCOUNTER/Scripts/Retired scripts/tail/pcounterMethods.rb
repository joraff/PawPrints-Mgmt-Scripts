#!/usr/bin/ruby

class Date
  def self.yesterday
    now - 1
  end
end

def lower(var1, var2)
  if var1 <= var2
    var1
  else
    var2
  end
end