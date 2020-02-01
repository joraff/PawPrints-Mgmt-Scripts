#!/usr/bin/ruby

require 'file/tail'
require 'fileutils'
require File.dirname(__FILE__)+'/pcounterMethods.rb'
require File.dirname(__FILE__)+'/dbconnect.rb'
require 'mysql'
require 'digest/md5'

# Step 1: rotate log file
# Step 2: import old log file into history
# Step 3: truncate temp table
# Step 4: import new log file to temp
# Step 5: tail new log file, import to temp

pathToData = 'C:\\PCOUNTER\\DATA\\'
oldLogFile = pathToData + "PCOUNTER.LOG"
newLogFile = pathToData + "PCOUNTER_" + Date.yesterday.strftime('%Y_%m%d') + ".LOG"
indexes = ['username', 'docname', 'queue', 'date', 'time', 'client', 'clientcode', 'subcode', 'papersize', 'optstring', 'size', 'pages', 'cost', 'balance']
db = Mysql.connect('macgyver', 'username', 'password', 'print_history')


$logfile = LogFile.new("#{pathToData}Scripts\\startup.log", "a+")

#####################
# Main Program
$logfile.puts "#{Time.now}: Begin execution of print history startup script."

  #Step 1
  $logfile.puts "#{Time.now}: Attempting to rotate PCOUNTER log file."
  if rotate_log(oldLogFile, newLogFile)  #Renames current logfile to yesterday's date for retention. Pcounter starts over with new logfile
    $logfile.puts "#{Time.now}: PCOUNTER.LOG rotated successfully. Inserting into print history DB."
    #Step 2
    jobs = fileToCSV(newLogFile)  #Create jobs array of yesterday's logfile data
    insertResult = insertJobs("print_history.history", jobs, 2500, db)
    if insertResult  #Insert yesterday's logfile data into permanent history table
      #Step 3
      $logfile.puts "#{Time.now}: #{jobs.length} jobs inserted in to print_history.history"
      result = true #set the result to true. Mysql.query will return a Mysql::Error on error, or nil on success
      result = db.query("TRUNCATE TABLE temp")  #Truncates the temp table to start over. Temp table was a less accurate reflection of yesterday's logfile data
      if result.nil?
        $logfile.puts "#{Time.now}: TEMP table truncated, moving on to tail."
      else
        $logfile.puts "#{Time.now}: Couldn't seem to truncate the temp table?"
      end
    else
      $logfile.puts "#{Time.now}: Couldn't insert jobs into history table. Skipped truncation of temp"
    end
  end

    
  

  
  #Step 4 (has been combined with step 5)
  # jobs = fileToCSV(oldLogFile)
  # insertJobs("print_history.temp", jobs, 1000)  #Catch up on jobs that were submitted while ^^ was executing. Unlikely to be much, if any

  

  #Step 5
  # The fun part!
  
  
  
  # First, get the last 1000 rows from the temp table
  sql = "SELECT * from temp order by id desc limit 1001"
  result = db.query(sql)
  existingJobsHashes = Array.new
  result.each_hash { |row|
    existingJobsHashes.push Digest::MD5.hexdigest("#{row['username']}#{row['docname']}#{row['printer']}#{row['optstring']}#{row['balance']}") 
  }
  
  $logfile.puts "#{Time.now}: Watching PCOUNTER.LOG for new jobs..."
  
  while 1 do
    if File.exist?(oldLogFile)
      File::Tail::Logfile.tail(oldLogFile, :backward => 10000, :interval => 1, :max_interval => 3) do |line|
        job = Hash.new
        elements = line.split(',')
        elements.each_index do |index|
          job.merge! Hash[ indexes.fetch(index) => elements.fetch(index)]
        end
        unless existingJobsHashes.include? Digest::MD5.hexdigest("#{job['username']}#{job['docname']}#{job['printer']}#{job['optstring']}#{job['balance']}")
          newdate = job['date'].split('/')
		      newdate = "#{newdate[2]}-#{newdate[0]}-#{newdate[1]}"
		      job['date'] = newdate
		      puts job['queue']
		      matchData = job['queue'].match(/\\{2,4}GUS\\{1,2}(.+)[ _-]{1}(?:\dsided|MAC|[A-C])*/)
		      job['printer'] = (matchData) ? matchData[1] : job['queue'].gsub(/\\{2,4}GUS\\{1,2}/, '')
		      
          
		      dbJob = HistoryTemp.new(job)
		      #$logfile.puts "New job from: #{dbJob.username}"
          unless dbJob.save
            $logfile.puts "#{Time.now}: job save failed:"
            dbJob.errors.each_full { |msg| $logfile.puts "\t" + msg }
            jobstr = ''
            puts job
            job.each_value do |element|
              jobstr << "#{element.rstrip},"
            end
            jobstr.gsub! /[, ]+$/, ''
            $logfile.puts "\tJob string: #{jobstr}"
          end
        else
          $logfile.puts "#{Time.now}: Job exists! Skipping..."
        end
      end
    else
		puts "error: log file doesn't exist to follow"
	end
  end
