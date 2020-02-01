printers = [
	"Alexander",
	"Allen",
	"BrooksFlats",
	"BrooksFlats_DP",
	"BrooksCollege",
	"BrooksCollege_DP",
	"Collins",
	"Dawson",
	"Heritage",
	"Kokernot",
	"Martin",
	"Memorial",
	"NorthRussell",
	"NorthRussell_DP",
	"NVCC4114",
	"Penland",
	"Penland_DP",
	"SouthRussell",
	"SouthRussell_DP",
	"Texana",
	"University"
]

printers.each { |p|
	puts "Setting permissions on #{p}"
	`subinacl.exe /printer #{p} /grant="BAYLOR\\CLL Print Admins"=F`
	`subinacl.exe /printer #{p} /grant="BAYLOR\\STS Print Admins"=F`
	`subinacl.exe /printer #{p} /grant="BAYLOR\\CLL Print Users"=P`
	`subinacl.exe /printer #{p} /deny="BAYLOR\\STS Print Abuse"=P`
	`subinacl.exe /printer #{p} /revoke="BAYLOR\\STS Print Permissions"`
	`subinacl.exe /printer #{p} /revoke="everyone"`
	`subinacl.exe /printer #{p} /revoke="power users"`
}