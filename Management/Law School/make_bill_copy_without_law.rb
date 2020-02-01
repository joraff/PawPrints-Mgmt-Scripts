#!/usr/bin/env ruby -wKU


ids_file = File.open("/Volumes/gus/AdminResources/Law\ School/ids.txt", 'r')
ids = []
ids_file.each_line do |l|
  ids.push l.strip
end
ids_file.close

bill = "/Volumes/gus/AdminResources/Billing/bill_20110504_1356.txt"

bill_file = File.open(bill, 'r')
new_bill_file = File.open((bill.gsub('.txt','')+".law.txt"), 'w')

bill_file.each_line do |line|
  id = line[4..12]
  unless ids.include? id
    new_bill_file.puts line
  else
    puts "Removing #{id}"
  end
end

bill_file.close
new_bill_file.close