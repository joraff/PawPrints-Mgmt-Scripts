# RestartService.ps1
# Author: STL
# Created: 6/22/2010
# Purpose: Restart service and dependencies
 
PARAM($svcName)
 
# Get dependent services
$depSvcs = Get-Service -name $svcName -dependentservices | Where-Object {$_.Status -eq "Running"} |Select -Property Name
 
# Check to see if dependent services are started
if ($depSvc -ne $null) {
	# Stop dependencies
	foreach ($depSvc in $depSvcs)
	{
		Stop-Service $depSvc.Name
		do
		{
			$service = Get-Service -name $depSvc.Name | Select -Property Status
			Start-Sleep -seconds 1
		}
		until ($service.Status -eq "Stopped")
	}
}
 
# Restart service
Restart-Service $svcName -force
do
{
	$service = Get-Service -name $svcName | Select -Property Status
	Start-Sleep -seconds 1
}
until ($service.Status -eq "Running")
 
 
$depSvcs = Get-Service -name $svcName -dependentservices |Select -Property Name
 
# We check for Auto start flag on dependent services and start them even if they were stopped before
foreach ($depSvc in $depSvcs)
{
	$startMode = gwmi win32_service -filter "NAME = '$($depSvc.Name)'" | Select -Property StartMode
	if ($startMode.StartMode -eq "Auto") {
		Start-Service $depSvc.Name
		do
		{
			$service = Get-Service -name $depSvc.Name | Select -Property Status
			Start-Sleep -seconds 1
		}
		until ($service.Status -eq "Running")
	}
}