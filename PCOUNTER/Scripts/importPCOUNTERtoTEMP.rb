#!/usr/bin/ruby

require 'rubygems'
require 'fileutils'
require File.dirname(__FILE__)+'/pcounterMethods.rb'
require 'mysql'
require 'time'

pathToData = "E:\\PCOUNTER\\DATA\\"
db = Mysql.connect('macgyver', '', 'password', 'print_history')

#####################
# Main Program

db.query("TRUNCATE TABLE temp");

file = pathToData + "PCOUNTER.LOG"

if File.exist? file
	puts "importing file #{file}... "
	jobs = fileToCSV(file)
	if jobs.length
		puts insertJobs("print_history.temp", jobs, 2500, db)  #Insert yesterday's logfile data into permanent history table
		puts "#{jobs.length} jobs imported\n"
	else
		puts "#{file}: no jobs"
	end
else
	puts "No file."
end

etime = "#{Time.now.to_i}.#{Time.now.usec}".to_f



