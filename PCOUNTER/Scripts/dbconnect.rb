#!/usr/bin/ruby

require 'rubygems'  
require 'active_record'  

ActiveRecord::Base.establish_connection(  
  :adapter => "mysql",  
  :host => "sqlserver",  
  :database => "print_history",
  :username => "username",
  :password => "password"
)  
  
class HistoryTemp < ActiveRecord::Base  
  set_table_name "temp"
  protected
    def validate
      errors.add_on_empty %w( username printer cost)
    end
end

class History < ActiveRecord::Base  
  set_table_name "history"
end
