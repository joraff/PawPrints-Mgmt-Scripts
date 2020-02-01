#!/usr/bin/ruby

#################
# Collection of methods that mostly pertain to 
# pcounter logfiles and the print history database.
# Written by Joseph Rafferty at Baylor University
#################



##########
# Extends the Date class with a yesterday object. Provides a Date object for exactly one day ago

class Date
  def self.yesterday
    Time.now - 86400
  end
end

class Job
  def initialize(job)
    self.username = job[0]
    self.docname = job[1]
  end
end

##########
# Given two variables, returns the lower value, assuming the two vars are comparable

def lower(var1, var2)
  if var1 <= var2
    var1
  else
    var2
  end
end


##########
# Attempt to provide a php print_r-esque method in ruby
# requires a hash - doesn't like arrays yet

def print_r(hash, level=0)
  result = "  "*level + "{\n"
  hash.keys.each do |key|
    result += "  "*(level+1) + "#{key} => "
    if hash[key].instance_of? Hash
      result += "\n" + print_r(hash[key], level+2)
    else 
      result += "#{hash[key]}\n"
    end
  end
  result += "  "*level + "}\n"
end


##########
# Takes an array of jobs (whose elements should already be in an array)
# and inserts them into the specified table of database db (MySQL object).
# Splits the jobs into several sql statements to avoid reaching max allowed
# packet size of the MySQL server

def insertJobs(tableName, jobs, limit, db)
  # Calculate how many loops of {limit} at a time we need to do to insert all the jobs in {jobs}
  loops = ((jobs.length.to_f)/limit).ceil
  (0...loops).each do |i| # non-inclusive loop, like i < loops
    sql = "INSERT INTO " + tableName.to_str
    sql << " (`username`, `docname`, `queue`, `date`, `time`, `client`, `subcode`, `clientcode`, `papersize`, `optstring`, `size`, `pages`, `cost`, `balance`, `printer`) VALUES "
    i = i*limit # Setup our lower bound for this loop. First loops will be 0, then in increments of {limit}
    (i...lower(i+limit,jobs.length)).each do |x| # stop if we've reached the number of jobs in {jobs}. non-inclusive since we started at 0
      job = jobs[x]
      if job.length # make sure there's data in the job before adding it to the insert
        jobstring = "("
        date = job[3]
        job[3] = sprintf("%s-%s-%s", date.slice(-4,4), date.slice(0,2), date.slice(3,2)) # format the date correctly for MySQL's default date format YYYY-MM-DD
        job.each do |element| 
          unless element.length
            element = ''
          end
          jobstring << "'#{Mysql.quote(element.rstrip)}'" + ","
        end
        matchData = job[2].match(/\\{2,4}GUS\\{1,2}(.+)[ _-]{1}(?:\dsided|MAC|[A-C])*/)
        matchValue = (matchData && matchData[1].class == String) ? matchData[1] : job[2].gsub(/\\{2,4}GUS\\{1,2}/, '')
        jobstring << "'#{Mysql.quote(matchValue.rstrip)}'" + "," # add the printer name to the end of the insert query
        sql << jobstring.gsub(/[, ]+$/, '') + "),"
      end
    end
    sql = sql.gsub(/[, ]+$/, '') # Trim spaces and commas off the end of the completed SQL statement
    puts sql
    if(db.query(sql) != nil) then return false end # Kinda weird, but the instance method MySQL.query returns a MySQL::Result object if we're doing a select, etc., a MySQL::Error object if an error was raised, or nil if the query was OK but no result returned. I hate that.
  end
  return true
end


##########
# Reads a PCOUNTER.LOG file and splits it into job-element arrays
# PCOUNTER.LOG files are CSV files with one job per line

def fileToCSV(file)
  jobs = Array.new
  if File.exist?(file)
    File.read(file).split("\n").each do |line|
      elements = line.split ","
      jobs.push(elements)
    end
  end
  jobs
end


##########
# Rotates a log file by renaming the current
# one and creating an empty replacement.
# Generic enough to use for any log file
# Note: send filenames as absolute paths
# 1: oldLogFile = the file which you want to rename
# 2: newLogFile = the new name for oldLogFile

def rotate_log(oldLogFile, newLogFile)
  if File.exist?(oldLogFile) &&
     File.writable?(File.dirname(oldLogFile)) &&
     File.writable?(File.dirname(newLogFile))
    unless File.exist?(newLogFile)
      begin
        File.rename(oldLogFile, newLogFile)  # rotate the log file
        FileUtils.touch oldLogFile          # create PCOUNTER.LOG file just in case pcounter won't create it
        return true
      rescue
        $logfile.puts "#{Time.now}: Something bad happened with renaming the logfile #{oldLogFile} or creating its replacement."
        return false
      end
    else
      $logfile.puts "#{Time.now}: Logfile #{newLogFile} already exists! Skipping log rotation."
      return false
    end
  else
    $logfile.puts "#{Time.now}: Either one of the logfiles isn't writable, or #{oldLogFile} doesn't exist."
    return false
  end
end

class LogFile < File
  def puts(s)
    super
    self.flush
  end
end