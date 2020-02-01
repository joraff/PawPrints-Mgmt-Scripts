#!/usr/bin/env ruby -wKU


require "rubygems"
require "active_record"

filename = "Spring_2010_Grad_Students.txt"
description = "Spring 2010 Corrected Additional Balance"

ActiveRecord::Base.establish_connection(
	:adapter => "mysql",
	:host => "server", 
	:username => "username", 
	:password => "password", 
	:database => "print_history" 
)

class History < ActiveRecord::Base
  set_table_name 'history'
end


f = File.new(filename)

$PTA = "C:\\PROGRA~1\\PCOUNT~1\\NT\\ACCOUNT.EXE"
failed = Array.new

h = History.all(:conditions => ["date = ? AND docname = ?", "2010-02-01", "Deposit: #{description}"])
u = Array.new
h.each { |row|
  u << row.username.upcase
}


f.each { |bearid|
  bearid.strip!.upcase!
  if bearid.length
    puts "Looking for: #{bearid}"
    
    if u.include? "BAYLOR\\#{bearid}"
      puts "==================\n#{bearid} already received deposit\n==================\n\n"
    else
      r = `#{$PTA} DEPOSIT #{bearid} 200 '#{description}'`
		  puts r
		  unless r.include? "New balance is"
		  	failed << bearid
		  end
	  end
  end
}


puts "Failed bearIDS:"
failed.each { |f| puts f }