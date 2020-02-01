#!/usr/bin/ruby

require 'file/tail'
require 'dbconnect.rb'
require 'digest/md5'

logfile = '/Volumes/PCOUNTER/DATA/PCOUNTER.LOG'
indexes = ['username', 'docname', 'printer', 'date', 'time', 'client', 'clientcode', 'subcode', 'papersize', 'optstring', 'size', 'pages', 'cost', 'balance']
backward = 100
counter = 1
hashes = Array.new


##
## First time the script is called, we should truncate the temp table to start over so we don't risk data mismatch
## Honestly we can probably just resume normally and rely on the backwards hash checking later in the script
##  since not much changes in the log file while the server is restarting.
## 

ActiveRecord::Base.connection.execute("TRUNCATE TABLE temp")

contents = IO.readlines(logfile, "\n")
if contents
  puts "Inserting #{contents.length} from log file"
  contents.each do |line|
    job = Hash.new
    elements = line.split(',')
    elements.each_index do |index|
      job.merge! Hash[ indexes.fetch(index) => elements.fetch(index)]
    end
    History.create(job)
  end
end

limit = (contents.length < backward) ? contents.length : backward

prevjobs = History.find(:all, :limit=>limit, :offset=>History.maximum('id')-limit )

prevjobs.each do |job| 
  hash = Digest::MD5.hexdigest("#{job.username}#{job.printer}#{job.docname}#{job.optstring}#{job.size}#{job.balance}")
  hashes.push(hash)
end

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
    puts "inserting job"
  end
end


