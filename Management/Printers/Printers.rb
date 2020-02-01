# Dependent on:
 # - HP UPD
 # - SetPrinter.exe (copy from w2k3 resource kit tools)
 # - SubInAcl.exe (download version > 4, do not copy from w2k3) 
 
RTPATH = "C:\\Program Files (x86)\\Windows Resource Kits\\Tools"
UPDPATH = "C:\\Drivers\\HP\\HP Universal Print Driver\\PCL6 v5.2.6.9321\\winxp_vista_x64\\install.exe"

unless File.exist? "#{UPDPATH}"
	puts "UPD installer doesn't exist at: #{UPDPATH}"
	exit
end

def install(printer, port)
  if printer.include?("2sided")
	`"#{UPDPATH}" /q /h /n"#{printer}" /sm"#{port}" /nd /npf /u /pfduplex=1`
  else
    `"#{UPDPATH}" /q /h /n"#{printer}" /sm"#{port}" /nd /npf /u`
  end
  `cscript "C:\\Windows\\System32\\Printing_Admin_Scripts\\en-US\\prncnfg.vbs" -t -p #{printer} -h #{printer} -shared -direct`
  `"#{RTPATH}\\setprinter.exe" #{printer} 8 "pdevmode=dmMediaType=284,dmPaperSize=1,dmFormName=Letter,dmFields=|formname"`
end

def set_duplex(printer)
  `"#{RTPATH}\\setprinter.exe" #{printer} 8 "pdevmode=dmDuplex=2,dmCollate=1,dmFields=|duplex collate"`
end

def set_default_acl(printer)
  `"#{RTPATH}\\subinacl.exe" /printer #{printer} /revoke=\"everyone\"`
	`"#{RTPATH}\\subinacl.exe" /printer #{printer} /revoke=\"power users\"`
	`"#{RTPATH}\\subinacl.exe" /printer #{printer} /grant=\"BAYLOR\\STS Print Admins\"=F`
	`"#{RTPATH}\\subinacl.exe" /printer #{printer} /grant=\"BAYLOR\\STS Print Permissions\"=P`
	`"#{RTPATH}\\subinacl.exe" /printer #{printer} /deny=\"BAYLOR\\STS Print Abuse\"=P`
end

def set_cll_acl(printer)
  `"#{RTPATH}\\subinacl.exe" /printer #{printer} /grant=\"BAYLOR\\CLL Print Admins\"=F`
	`"#{RTPATH}\\subinacl.exe" /printer #{printer} /grant=\"BAYLOR\\CLL Print Users\"=P`
	`"#{RTPATH}\\subinacl.exe" /printer #{printer} /revoke=\"BAYLOR\\STS Print Permissions\"`
end

def set_bus_acl(printer)
  `"#{RTPATH}\\subinacl.exe" /printer #{printer} /grant=\"BAYLOR\\G HSB Casey Computer Center\"=M`
end

def set_law_acl(printer)
  `"#{RTPATH}\\subinacl.exe" /printer #{printer} /grant=\"BAYLOR\\G Law Printer Admins\"=F`
end
