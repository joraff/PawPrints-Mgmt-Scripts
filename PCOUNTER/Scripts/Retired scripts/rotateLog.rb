#!/usr/bin/ruby

require 'file/tail'
require 'digest/md5'
require 'c:\PCOUNTER\DATA\Scripts\pcounterMethods.rb'
require 'mysql'

logfilePrefix = 'c:\PCOUNTER\DATA'
logfile = "#{logfilePrefix}\\PCOUNTER_test.LOG"
indexes = ['username', 'docname', 'printer', 'date', 'time', 'client', 'clientcode', 'subcode', 'papersize', 'optstring', 'size', 'pages', 'cost', 'balance']
backward = 100
counter = 1
hashes = Array.new
jobs = Array.new
limit=1000 # this is the number of rows we want to insert at a time into the db


db = Mysql.connect('gus', 'username', 'password', 'print_history')


if File.exist?(logfile) && File.writable?(logfile)
  newfile = "#{logfilePrefix}/PCOUNTER_test_#{Date.yesterday.strftime('%Y_%m%d')}.LOG"
  if File.exist?(newfile) then File.rename(newfile, "#{newfile}.dup") end
  if File.rename(logfile, newfile)
    File.read(newfile).split("\n").each do |line|
      jobs.push(line.split(","))
    end
  end
  
  # Chances are no one printed while we renamed the file, so let's create the file so we can tail it later
  File.open(logfile, 'a')
else
  puts "Logfile '#{logfile}' not found or not writable! Skipping file import."
end

if jobs.length > 0
  (1..(jobs.length/limit.to_f).ceil).each do |i|
    sql = "INSERT INTO `temp` ( `username`, `docname`, `printer`, `date`, `time`, `client`, `subcode`, `clientcode`, `papersize`, `optstring`, `size`, `pages`, `cost`, `balance`) VALUES "
    ((i-1)*limit..lower(i*limit, (jobs.length-1))).each do |x| 
      sql << "('#{Mysql.quote(jobs[x][0])}', '#{Mysql.quote(jobs[x][1])}', '#{Mysql.quote(jobs[x][2])}', '#{Mysql.quote(jobs[x][3])}', '#{Mysql.quote(jobs[x][4])}', '#{Mysql.quote(jobs[x][5])}', '#{Mysql.quote(jobs[x][6])}', '#{Mysql.quote(jobs[x][7])}', '#{Mysql.quote(jobs[x][8])}', '#{Mysql.quote(jobs[x][9])}', '#{Mysql.quote(jobs[x][10])}', '#{Mysql.quote(jobs[x][11])}', '#{Mysql.quote(jobs[x][12])}', '#{Mysql.quote(jobs[x][13].rstrip)}'), "
    end
    sql.gsub!(/[, ]+$/, '')
    db.query(sql)
  	if db.error.empty?
  	end
  	puts "============ END OF BLOCK #{i} ============"
  end
end

