@rem Jeff_Wilson D_Dunn 12 Oct 2005
@rem updated for new server 11 Feb 2008
@rem updated for windows server 2008 May 2, 2011 - Joseph_Rafferty

@rem Make sure we know where we start from
cd "C:\Program Files (x86)\Pcounter for NT\NT"

@rem Create backup of Baylor accounts
account backup baylor

@rem clear the variable myfile
@set myfile=

@rem List all PCounter backup batch scripts in this directory
@for /f %%i in ('"dir /b Pcounter_BAYLOR_Backup*.bat"') do @set myfile=%%i

@rem move Baylor account backup script to the correct folder
move %myfile% "C:\AdminResources\Billing"

@rem Make sure we know where we start from
cd "C:\AdminResources\Billing"

@rem lockbox.pl this creates several files including the ones that need to be sent to production services
perl lockbox.pl -f %myfile%

goto FAIL_CODE_%ERRORLEVEL%

:FAIL_CODE_0
echo testing fail_code_0
goto THE_REAL_EXIT

@rem need to check errorlevel and possibly exit out if we got dorked

@rem List all setbal files (this is used to reset the allowances) in this directory
for /f %%i in ('"dir /b setbal_*.bat"') do set mycmd=%%i

@rem Execute the setbal file so that the pages are added back into student allowances
call %mycmd%

@rem setup a Date, Time stamp and create a new folder using it 
@rem grab the two digit day-of-month
set today=%date:~7,2%
@rem grab the two digit month
set thismonth=%date:~4,2%
@rem grab the four digit year
set thisyear=%date:~10,4%
@rem strip out the colon's from the timestamp
set mytimestamp=%TIME::=%
@rem grab the four-digit HHMM timestamp
set mytimestamp=%mytimestamp:~0,-5%
@rem build a filepath with the results
set myfilepath="d:\PawPrints Perl\Billing\%thismonth%_%today%_%thisyear%_%mytimestamp%"
@rem create a folder with uniquely named path
mkdir %myfilepath%

set EMAIL=David_Burns@baylor.edu,Carl_Flynn@baylor.edu,Richard_Gerik@baylor.edu
set PawPrintsBillingSubject=PawPrints Bill Summary for %date%

@rem I need to find the summary file to email to Electronic Library Folks
@for /f %%i in ('"dir /b lockbox_*.log"') do @set myfile=%%i
@for /f %%i in ('"dir /b bill_*_*.txt"') do @set myattachment=%%i
blat.exe %myfile% -s "%PawPrintsBillingSubject%" -t %EMAIL% -attacht %myattachment%

@rem We need to email the file to Production Services
set EMAIL=Carl_Flynn@baylor.edu,Ava_Knapek@baylor.edu,Ann_Carter@baylor.edu
set PawPrintsBillingSubject=PawPrints Bill for %date%
set PawPrintsBillingBody=PawPrintsBillingBody.txt
@for /f %%i in ('"dir /b bill_*_*.txt"') do @set myattachment=%%i
blat.exe %PawPrintsBillingBody% -s "%PawPrintsBillingSubject%" -t %EMAIL% -attach %myattachment%

@rem Time to move some files around

@rem first we are going to get the setbal and move it to the folder we just created
for /f %%i in ('"dir /b setbal_*.bat"') do set mycmd=%%i
move %mycmd% %myfilepath%

@rem now we are going to move the Pcounter Backup File
@for /f %%i in ('"dir /b Pcounter_BAYLOR_Backup*.bat"') do @set myfile=%%i
move %myfile% %myfilepath%

@rem now for the lockbox log file
@for /f %%i in ('"dir /b lockbox_*.log"') do @set myfile=%%i
move %myfile% %myfilepath%

@rem Finally move the bill file
@for /f %%i in ('"dir /b bill_*_*.txt"') do @set myfile=%%i
move bill_*_*.txt %myfilepath%

goto THE_REAL_EXIT

:FAIL_CODE_1
echo FAIL_CODE_1
goto THE_REAL_EXIT

:FAIL_CODE_2
echo Lockbox.pl failed trying to fetch student ID
goto THE_REAL_EXIT

:FAIL_CODE_8
echo Lockbox.pl failed with some kind of DB problem
goto THE_REAL_EXIT

:FAIL_CODE_9
echo I guess you need some help, eh?
goto THE_REAL_EXIT


:THE_REAL_EXIT