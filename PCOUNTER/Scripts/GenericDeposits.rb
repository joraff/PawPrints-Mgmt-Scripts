
trap("INT") { exit }

file = ARGV[0]
unless file
  puts "No arguments given. Please provide a path to a file to use for deposits."
  exit
end
  
unless File.exist?(file)
  puts "File #{file} doesn't exist!"
else
  
  loop do
    print "Is #{file} the correct file to use? [yes/no] "
    confirmFile = STDIN.gets.strip
    unless ["yes", "no"].include?(confirmFile)
      puts "Please enter yes or no"
      retry
    end
    break
  end
  
  loop do
    print "How many pages would you like to deposit? "
    $pages = STDIN.gets.strip.to_i
    unless $pages > 0
      puts "Must be greater than 0"
      retry
    end
    break
  end
  
  students = File.read(file).split("\n")
  
  loop do
    print "Confirm deposit of #{$pages} pages into #{students.length} accounts? [yes/no] "
    confirm = STDIN.gets.strip
    unless ["yes", "no"].include?(confirm)
      puts "Please enter yes or no"
      retry
    end
    break
  end
  
  pathToAccountExe = 'C:\Progra~1\Pcount~1\NT\ACCOUNT';
  
  students.each do |student|
    result = `#{pathToAccountExe} DEPOSIT #{student.strip} #{$pages}`
    if result.include? "Unable"
      puts "Error with account: #{student.strip}"
    end
  end
  
  puts "\nDeposits Made."
end
  