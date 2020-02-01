#!/usr/bin/ruby

=begin

Requests.rb
© 2009 Baylor University
Written by Joseph Rafferty

Request class for use with PawPrints print history services

=end

require "rubygems"
require "active_record"
require "net/smtp"
require "tlsmail"

ActiveRecord::Base.establish_connection(
	:adapter => "mysql",
	:host => "macgyver", 
	:username => "username", 
	:password => "password", 
	:database => "print_history" 
)

class Request < ActiveRecord::Base

	@@pathToAccountExe = "C:\\Program Files (x86)\\Pcounter for NT\\NT\\account.exe"

  def self.getUnprocessed
	  find(:all, :conditions => [" approved != 0 AND processed = 0 "])
  end

  def refund(*args)
      puts "approved: #{self.approved}"
      if self.approved == 1
          comment = args[0] ? args[0] : "Refund request from #{self.timestamp.strftime('%m/%d/%Y')}"
          result = `"#{@@pathToAccountExe}" DEPOSIT #{self.username} #{self.pages_approved} "#{comment}"`.split(' ')
          oldBalance = result[5].to_i
          newBalance = result[9].to_i
          puts "#{newBalance} > #{oldBalance}"
          if newBalance > oldBalance
            self.processed = 1
            self.refund_timestamp = Time.now
            if self.save
                self.emailPatron
            end
          else
            false
          end
      elsif self.approved == -1
          self.processed = 1
          self.refund_timestamp = Time.now
          if self.save
              self.emailPatron
          end
      end
  end

  def approve
	#implement when needed
  end

  def deny
	#implement when needed
  end
  
  def emailPatron
      Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
      smtp = Net::SMTP.start('mail.baylor.edu', 25, 'baylor.edu','pawprints','Delverkey9', :login)
      if self.approved == 1
          
		msgstr = <<-end.here_with_pipe
			|From: PawPrints Administrator <pawprints@baylor.edu>
			|To: #{self.username} <#{self.username}@baylor.edu>
			|Subject: PawPrints Refund Approved
			|
			|Dear #{self.username},
			| 
	        |Thank you for using PawPrints. We're sorry you had a problem, but are happy to let you know that you've been refunded #{self.pages_approved} #{"page".cond_pluralize(self.pages_approved)}.
		    |Your balance should immediately reflect the increase.
		    |
		    |#{self.comment}
		    | 
	        |Regards,
	        | 
	        |The PawPrints Team
	        |
	        |This email was concerning a request made on #{self.timestamp} with the following description: #{self.reason}
	        |
	    end
		
		smtp.send_message msgstr, 'pawprints@baylor.edu', "#{self.username}@baylor.edu"
		smtp.send_message msgstr, 'pawprints@baylor.edu', "pawprints@baylor.edu"
		puts msgstr
		smtp.finish
	end
	
	if (self.approved == -1) && (self.donotify == 1)
	    
		msgstr = <<-end.here_with_pipe
			|From: PawPrints Administrator <pawprints@baylor.edu>
			|To: #{self.username} <#{self.username}@baylor.edu>
			|Subject: PawPrints Refund Denied
			|
			|Dear #{self.username},
			| 
			|Unfortunately, we were unable to approve your request for a refund on your PawPrints account.
			|If you have any questions, please feel free to reply to this email and someone will get back to you shortly.
			|
			|#{self.comment}
			|
			|Regards,
			|
			|The PawPrints Team
			|
			|This email was concerning a request made on #{self.timestamp} with the following description: #{self.reason}
		end
		
		smtp.send_message msgstr, 'pawprints@baylor.edu', "#{self.username}@baylor.edu"
		smtp.send_message msgstr, 'pawprints@baylor.edu', "pawprints@baylor.edu"
		puts msgstr
		smtp.finish
	end
  end
end


class String
  def here_with_pipe
	lines = self.split("\n")
	lines.map! {|c| c.sub!(/\s*\|/, '')}
	new_string = lines.join("\n")
	self.replace(new_string)
  end
  
  def cond_pluralize(n)
  	self + (n > 1 ? 's' : '')
  end
end

