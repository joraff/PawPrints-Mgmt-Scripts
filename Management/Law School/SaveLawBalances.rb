#!/usr/bin/env ruby -wKU

=begin
Uncomment this section when/if there's ever an updated AD group for these students

require 'rubygems'
require 'net/ldap'

ldap = Net::LDAP.new :host => "marge.baylor.edu", :port => 389, :auth => {  :username => 'BAYLOR\sts_install', 
																			:password => "[B1g   Mac]", 
																			:method => :simple }
treebase = "dc=baylor,dc=edu"                                                                           

if ldap.bind
	filter = Net::LDAP::Filter.eq( "cn", "G Law Student Paw" )
	results = ldap.search( :base => treebase, :filter => filter )

	lawStudents = results[0][:member].each { |member| member.sub!(/CN=([^,]+).+/, '\1') }
	lawStudents.sort!

	if lawStudents.length
		f = File.new("lawStudents#{Time.now.strftime('%Y%m%d')}.txt", "w")
		f.puts lawStudents
		f.close
	else
		puts "no students in that group"
	end
else
	puts "Couldn't bind ldap"
end

=end
$PTA = "C:\\PROGRAM FILES (x86)\\Pcounter for NT\\NT\\ACCOUNT.EXE"


f = File.new("Current_Law_Students.txt")
n = File.new("Law_Students_Balances-#{Time.now.strftime('%Y-%m-%d')}.txt", 'w')

f.each { |line|
	line.strip!
	line = line[0..19]
	if line.length
		bal = `"#{$PTA}" VIEWBAL #{line}`.sub(/.+\s(\d+)\n.+\n/, '\1')
		n.puts "#{line}\t#{bal}"
		puts "#{line}\t#{bal}"
	else
		puts "bad line"
	end
}
n.close
