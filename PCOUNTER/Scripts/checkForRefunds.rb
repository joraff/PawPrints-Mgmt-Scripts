#!/usr/bin/ruby

=begin

checkForRefunds.rb
© 2009 Baylor University
Written by Joseph Rafferty

Checks the print_history.requests table for approved but unprocessed requests.
If there are unprocessed requests, it executes account.exe for the username on the request giving back the number of pages on the request.
On success, it emails the username a report that their request was approved.

=end

$logfile = File.new("C:\\PCOUNTER\\DATA\\Scripts\\checklog.log", 'a+')

require "C:\\PCOUNTER\\DATA\\Scripts\\Requests.rb"

unprocessed = Request.getUnprocessed
$logfile.puts "#{Time.now}: Processing #{unprocessed.length} refunds."
unprocessed.each do |request|
  unless request.refund then $logfile.puts "#{Time.now}: Request id #{request.id} failed." end
end