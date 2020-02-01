#!/usr/bin/ruby

require 'file/tail'
require 'dbconnect.rb'
require 'digest/md5'
require 'pcounterMethods.rb'
require 'mysql'

logfilePrefix = '/Users/joraff/Desktop'
logfile = "#{logfilePrefix}/PCOUNTER_test.LOG"
indexes = ['username', 'docname', 'printer', 'date', 'time', 'client', 'clientcode', 'subcode', 'papersize', 'optstring', 'size', 'pages', 'cost', 'balance']
backward = 100
counter = 1
hashes = Array.new
jobs = Array.new
limit=1000 # this is the number of rows we want to insert at a time into the db

# Create a MySQL object to put logfile rows into the DB
db = Mysql.connect('gus', 'username', 'password', 'print_history')

# 1. Check if the logfile and the directory we're working in exists and is writable
# 2. Rename the logfile to be of yesterday's date
# 3. Create a jobs array from each CSV and each line

if File.exist?(logfile) && File.writable?(logfile) && File.writable?(logfilePrefix)
  newfile = "#{logfilePrefix}/PCOUNTER_test_#{Date.yesterday.strftime('%Y_%m%d')}.LOG"
  if File.exist?(newfile) then File.rename(newfile, "#{newfile}.dup") end
  if File.rename(logfile, newfile)
    File.read(newfile).split("\n").each do |line|
      jobs.push(line.split(","))
    end
  end
else
  puts "Logfile '#{logfile}' not found or not writable! Skipping file import."
end

if jobs.length > 0
  (1..(jobs.length/limit.to_f).ceil).each do |i|
    sql = "INSERT INTO `temp` ( `username`, `docname`, `printer`, `date`, `time`, `client`, `subcode`, `clientcode`, `papersize`, `optstring`, `size`, `pages`, `cost`, `balance`) VALUES "
    ((i-1)*limit..lower(i*limit, (jobs.length-1))).each do |x| 
      # Refactor this! Not very rubyish
      sql << "('#{Mysql.quote(jobs[x][0])}', '#{Mysql.quote(jobs[x][1])}', '#{Mysql.quote(jobs[x][2])}', '#{Mysql.quote(jobs[x][3])}', '#{Mysql.quote(jobs[x][4])}', '#{Mysql.quote(jobs[x][5])}', '#{Mysql.quote(jobs[x][6])}', '#{Mysql.quote(jobs[x][7])}', '#{Mysql.quote(jobs[x][8])}', '#{Mysql.quote(jobs[x][9])}', '#{Mysql.quote(jobs[x][10])}', '#{Mysql.quote(jobs[x][11])}', '#{Mysql.quote(jobs[x][12])}', '#{Mysql.quote(jobs[x][13].rstrip)}'), "
    end
    sql.gsub!(/[, ]+$/, '')
    db.query(sql) # will db.num_rows() return the number of rows inserted?
    
  	puts "============ END OF BLOCK #{i} ============"
  end
end


# Truncate temp table in DB before we start importing the tail following

sql = "TRUNCATE TABLE temp"

File::Tail::Logfile.tail(logfile, :backward => backward, :interval => 1, :max_interval => 3) do |line|
  job = Hash.new
  
  elements = line.split(',')
  elements.each_index do |index|
    job.merge! Hash[ indexes.fetch(index) => elements.fetch(index)]
  end
  if counter <= limit
    hash = Digest::MD5.hexdigest("#{job['username']}#{job['printer']}#{job['docname']}#{job['optstring']}#{job['size']}#{job['balance']}")
    unless hashes.include?(hash)
      History.create(job)
      puts "no hash match - inserting job"
    else
      puts "job exists, skipping"
    end
    counter += 1
  else
    puts "inserting job" + job
  end
end

# Chances are no one printed while we renamed the file, so let's create the file so we can tail it later
 File.new(logfile, 'a+')
 
 # Remove these lines for production version
 File.delete(logfile)
 File.rename(newfile, logfile)
 # End remove for production version
