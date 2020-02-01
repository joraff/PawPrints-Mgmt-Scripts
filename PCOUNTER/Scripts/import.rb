#!/usr/bin/ruby

require 'rubygems'
require 'fileutils'
require File.dirname(__FILE__)+'/pcounterMethods.rb'
require File.dirname(__FILE__)+'/dbconnect.rb'
require 'mysql'
require 'time'

pathToData = 'C:\\PCOUNTER\\DATA\\'
db = Mysql.connect('server', 'username', 'password', 'print_history')

#####################
# Main Program
puts "argv length = #{ARGV.length}"
if ARGV.length >= 2
  start_date = (Time.parse ARGV[0]).to_i
  end_date = (Time.parse ARGV[1]).to_i
end
if start_date && end_date && start_date <= end_date
  stime = "#{Time.now.to_i}.#{Time.now.usec}".to_f
  totalJobs = 0

  curr_date = start_date

  while curr_date <= end_date do

	file = pathToData + Time.at(curr_date).strftime("PCOUNTER_%Y_%m%d.LOG")
	puts file
	if File.exist? file
	  puts "importing file #{file}... "
	  jobs = fileToCSV(file)
	  if jobs.length
		insertJobs("print_history.history", jobs, 2500, db)  #Insert yesterday's logfile data into permanent history table
		puts "#{jobs.length} jobs imported\n"
		totalJobs += jobs.length
	  else
		puts "#{file}: no jobs"
	  end
	end

	curr_date += 86400
  end

  etime = "#{Time.now.to_i}.#{Time.now.usec}".to_f
  print "#{totalJobs} jobs inserted in #{sprintf('%.4f', etime-stime)} seconds\n"

else
  puts "Dates all screwed up!\n"
end


