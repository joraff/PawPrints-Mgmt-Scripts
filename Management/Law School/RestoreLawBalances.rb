#!/usr/bin/env ruby -wKU

f = File.new("Law_Students_Balances-#{Time.now.strftime('%Y-%m-%d')}.txt")

$PTA = "C:\\PROGRAM FILES (x86)\\PCOUNTER FOR NT\\NT\\ACCOUNT.EXE"
failed = Array.new

f.each { |line| 
	id, bal = line.strip.split("\t") 
	if id.length
		r = `"#{$PTA}" BALANCE #{id} #{bal}`
		puts r
		unless r.include? "New balance is"
			failed << id
		end
	end
}

puts "Failed bearIDS:"
puts failed