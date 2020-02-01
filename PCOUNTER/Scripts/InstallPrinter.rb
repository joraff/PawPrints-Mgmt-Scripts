#######################################
# InstallPrinter.rb
# Copyright 2009 Baylor University
# Written by joseph_rafferty@baylor.edu
# Automates the install of a printer with HP's universal print driver.
#
# NOTE: PCL6 must be used for the duplex command to have effect. Otherwise you must set that manually.
#######################################

# clears the input. Windows only
system('cls')
# *nix only 
system('clear')

# ensure a pretty exit
trap("INT") {
	print "\nGoodbye"
	exit
}

print "Printer name: "
# get printer name. remove newline and any trailing whitespace
printer = gets.strip


print "Port name: PCOUNT_"
# get port name. remove newline and any trailing whitespace
port = "PCOUNT_" + gets.strip

# prompt if we want this queue to duplex by default
def get_duplex
	print "Duplex? [yes/no]: "
	@duplex = gets.strip.downcase
	unless ["yes", "no"].include? @duplex
		puts "Please enter yes or no"
		get_duplex
	end
end

# prompt if we want to create both queues (_1sided and _2sided)
def get_create_both
	print "Create both 1sided and 2sided? [yes/no]: "
	@both = gets.strip.downcase
	unless ["yes", "no"].include? @both
		puts "Please enter yes or no"
		get_create_both
	end
	if @both == "no"
		get_duplex
	end
end
get_create_both

# prompt to see if this is a special printer
def get_extra
	print "Business, CLL, or Law? [bus/cll/law/no]: "
	@extra = gets.strip.downcase
	unless ["bus", "law", "cll", "no"].include? @extra
		puts "Please enter bus, cll, law, or none (no)"
		get_extra
	end
end
get_extra

def get_upd_path
	print "Path to the print driver [default = C:\\drivers\\UPD5.0.1-PCL6-x86]: "
	@upd_path = gets.strip
	if @upd_path.empty?
		@upd_path = "C:\\drivers\\UPD5.0.1-PCL6-x86"
	end	
end
get_upd_path

def do_install(p, d, port)
	puts `#{@upd_path}\\install.exe /q /h /n"#{p}" /sm"#{port}" /nd /npf /u`
	puts `cscript "C:\\WINDOWS\\system32\\prncnfg.vbs" -t -p #{p} -h #{p} +shared -direct`
	`subinacl.exe /printer #{p} /revoke=\"everyone\"`
	`subinacl.exe /printer #{p} /revoke=\"power users\"`
	`subinacl.exe /printer #{p} /grant=\"BAYLOR\\STS Print Admins\"=F`
	`subinacl.exe /printer #{p} /grant=\"BAYLOR\\STS Print Permissions\"=P`
	`subinacl.exe /printer #{p} /deny=\"BAYLOR\\STS Print Abuse\"=P`
	puts `setprinter #{p} 8 "pdevmode=dmMediaType=284,dmPaperSize=1,dmFormName=Letter,dmFields=|formname"`

	if d == "yes"
		puts `setprinter #{p} 8 "pdevmode=dmDuplex=2,dmCollate=1,dmFields=|duplex collate"`
	end

	case @extra
		when "bus"
			puts "Adding Business Admins"
			`subinacl.exe /printer #{p} /grant="BAYLOR\\Business Print Admins"=M`
		when "cll" 
			puts "Adding CLL Admins and Users"
			`subinacl.exe /printer #{p} /grant="BAYLOR\\CLL Print Admins"=F`
			`subinacl.exe /printer #{p} /grant="BAYLOR\\CLL Print Users"=P`
			puts "Revoking Broad Print Permissions"
			`subinacl.exe /printer #{p} /revoke="BAYLOR\\STS Print Permissions"`
		when "law"
			puts "Adding Law Admins"
			`subinacl.exe /printer #{p} /grant="BAYLOR\\Law Print Admins"=F`
	end
end # do_install method
if @both == "yes"
	do_install("#{printer}_2sided", "yes", port)
	do_install("#{printer}_1sided", "no", port)
else
	do_install(printer, @duplex, port)
end
