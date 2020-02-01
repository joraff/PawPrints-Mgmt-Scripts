#!/usr/bin/ruby

require 'rubygems'  
require 'active_record'  

ActiveRecord::Base.establish_connection(  
  :adapter => "mysql",  
  :host => "gus.baylor.edu",  
  :database => "print_history",
  :username => "username",
  :password => "password"
)  
  
class History < ActiveRecord::Base  
  set_table_name "temp"
end