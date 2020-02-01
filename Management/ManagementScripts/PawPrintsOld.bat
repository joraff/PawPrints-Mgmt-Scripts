@rem Purpose: Account Managment of PawPrints system at Baylor University
@rem Date: Dec 29 2003

@rem Move to the correct directory
rem c:
rem cd c:\Pawprints
rem pause





@echo off
:start

@rem For debugging (repeated invocations), I am reseting these values
set USERNAME=
set AMOUNT=
set COMMENT=
set BALANCE=
set PASSWORD=
set FULLNAME=
set CODE=
cls
echo.
echo.
echo.
echo                  PawPrints Account Manager
echo.
echo.
echo            Please choose from the following menu:
echo.
echo       a )  Add to a user's account balance.
echo       b )  Set a user's account balance.
echo       c )  Set a user's credit limit.
echo       d )  Subtract from a user's account balance.
echo       e )  Set a user's auto client code.
echo       f )  View a user's account balance.
echo       g )  Create a new PrinterPopupUsers account.
echo       h )  Read the global settings from Pcounter data server.
echo       i )  Send email to user.
echo       j )  Send email to users below some balance.
echo       k )  Add to each user's balance from a text file.
echo       l )  Configure WebClient (This option is only avalible on GUS)
echo       m )  Print Error
echo       n )  Configure Dcode Webclient
echo       o )  Exit
echo.      
echo.
"\\gus\pawprints\Files\choice.com" /cabcdefghijklmno /n
if errorlevel 15 goto :end_all
if errorlevel 14 goto :configure_dcode_webclient
if errorlevel 13 goto :printer_error
if errorlevel 12 goto :webClient
if errorlevel 11 goto :multiadd
if errorlevel 10 goto :below
if errorlevel 9  goto :sendmail
if errorlevel 8  goto :config
if errorlevel 7  goto :create
if errorlevel 6  goto :balance
if errorlevel 5  goto :autocode
if errorlevel 4  goto :subtract
if errorlevel 3  goto :limit
if errorlevel 2  goto :set
if errorlevel 1  goto :add
goto error

:webClient
d:
cd inetroot
cd cgi-bin
webclient config
pause
goto start

:multiadd
call "\\gus\pawprints\Files\multiadd.bat"
pause
goto start

:below
call "\\gus\pawprints\Files\belowbal.bat"
goto start

:add
cls
echo.
echo.
set /p USERNAME="Bear_ID: "

@rem THESe PATHS ARE CURRENT FOR GUS
"\\gus\www\cgi-bin\account.exe" viewbal %USERNAME%
echo.
set /p AMOUNT="Please enter a deposit amount: "
set /p COMMENT="Please enter a comment: "
"\\gus\www\cgi-bin\account.exe" DEPOSIT %USERNAME% %AMOUNT% %COMMENT%
pause
goto start


:printer_error
d:
cd "d:\PawPrints Accounting\Files"
cls
echo.
echo.
set /p USERNAME="Bear_ID: "
@rem THESe PATHS ARE CURRENT FOR GUS
"\\gus\www\cgi-bin\account.exe" viewbal %USERNAME%
echo.


echo Would you like to add pages to this users allowance?
echo An email will be sent to the user if you choose to YES
echo A 'declined' message will be sent to the user if you choose NO. 
"\\gus\pawprints\Files\choice.com" /cyn /n
if errorlevel 2 goto :printer_error_declined
if errorlevel 1 goto :printer_error_add


:another
echo Would you like to check another user?

"\\gus\pawprints\Files\choice.com" /cyn /n
if errorlevel 2 goto :start
if errorlevel 1 goto :printer_error

:printer_error_declined
@regedit /s "\\gus\pawprints\files\blat.reg"
if exist "d:\PawPrints Accounting\Files\PawPrintsPrinterErrorBody.txt" del "d:\PawPrints Accounting\Files\PawPrintsPrinterErrorBody.txt"
if exist "c:\windows\PawPrintsPrinterErrorBody.txt" del "c:\windows\PawPrintsPrinterErrorBody.txt"
set EMAIL=%USERNAME%@baylor.edu
set PawPrintsPrinterErrorSubject=PawPrintsPrinterErrorSubject.txt
set PawPrintsPrinterErrorBody=PawPrintsPrinterErrorBody.txt
echo %USERNAME%, >> PawPrintsPrinterErrorBody.txt
echo. >> PawPrintsPrinterErrorBody.txt
echo Your request for page credit has been declined. Please note that page credit will only be issued for problems due to printer error. >> PawPrintsPrinterErrorBody.txt
echo. >> PawPrintsPrinterErrorBody.txt
echo pawprints@baylor.edu >> PawPrintsPrinterErrorBody.txt
echo http://www.baylor.edu/pawprints >> PawPrintsPrinterErrorBody.txt

blat.exe %PawPrintsPrinterErrorBody% -s "PawPrints Printer Error" -t %EMAIL%

if exist "d:\PawPrints Accounting\Files\PawPrintsPrinterErrorBody.txt" del "d:\PawPrints Accounting\Files\PawPrintsPrinterErrorBody.txt"
if exist "c:\windows\PawPrintsPrinterErrorBody.txt" del "c:\windows\PawPrintsPrinterErrorBody.txt"
pause
goto :another

:printer_error_add
echo.
set /p AMOUNT="Please enter a deposit amount: "
set COMMENT=Printer Error
"\\gus\www\cgi-bin\account.exe" DEPOSIT %USERNAME% %AMOUNT% %COMMENT%
GOTO :EMAIL_PRINT_ERROR

:EMAIL_PRINT_ERROR
@regedit /s "\\gus\pawprints\files\blat.reg"
if exist "d:\PawPrints Accounting\Files\PawPrintsPrinterErrorBody.txt" del "d:\PawPrints Accounting\Files\PawPrintsPrinterErrorBody.txt"
if exist "c:\windows\PawPrintsPrinterErrorBody.txt" del "c:\windows\PawPrintsPrinterErrorBody.txt"
set EMAIL=%USERNAME%@baylor.edu
set PawPrintsPrinterErrorSubject=PawPrintsPrinterErrorSubject.txt
set PawPrintsPrinterErrorBody=PawPrintsPrinterErrorBody.txt
echo %USERNAME%, >> PawPrintsPrinterErrorBody.txt
echo. >> PawPrintsPrinterErrorBody.txt
echo I have added %AMOUNT% pages back into your PawPrints print allowance.  We are sorry for any inconvenience this may have caused you. >> PawPrintsPrinterErrorBody.txt
echo. >> PawPrintsPrinterErrorBody.txt
echo pawprints@baylor.edu >> PawPrintsPrinterErrorBody.txt
echo http://www.baylor.edu/pawprints >> PawPrintsPrinterErrorBody.txt

blat.exe %PawPrintsPrinterErrorBody% -s "PawPrints Printer Error" -t %EMAIL%

if exist "d:\PawPrints Accounting\Files\PawPrintsPrinterErrorBody.txt" del "d:\PawPrints Accounting\Files\PawPrintsPrinterErrorBody.txt"
if exist "c:\windows\PawPrintsPrinterErrorBody.txt" del "c:\windows\PawPrintsPrinterErrorBody.txt"
pause
goto :another


:sendmail
call "\\gus\pawprints\files\sendmail.bat"
goto start

:set
cls
echo.
echo.
set /p USERNAME="Bear_ID: "
set /p AMOUNT="Balance: "
set /p COMMENT="Comment: "

@rem THESE PATHS WILL NEED TO BE CHANGED TO GUS ONCE THIS FILE IS READY TO GO PRODUCTION!!
"\\gus\www\cgi-bin\account.exe" BALANCE %USERNAME% %AMOUNT% %COMMENT%
pause
goto start


:limit
call "\\gus\pawprints\files\limit.bat"
goto start

:subtract
cls
echo.
echo.
set /p USERNAME="Bear_ID: "
set /p AMOUNT="Charge Amount: "
set /p COMMENT="Comment: "

@rem THESE PATHS WILL NEED TO BE CHANGED TO GUS ONCE THIS FILE IS READY TO GO PRODUCTION!!
"\\gus\www\cgi-bin\account.exe" CHARGE %USERNAME% %AMOUNT% %COMMENT%
pause
goto start

:autocode
cls
echo.
echo.
echo This function is not currently being used.
@rem set /p USERNAME="Bear_ID: "
@rem set /p CODE="Auto Client Code: "

@rem THESE PATHS WILL NEED TO BE CHANGED TO GUS ONCE THIS FILE IS READY TO GO PRODUCTION!!
@rem "\\gus\www\cgi-bin\account.exe" AUTOCODE %USERNAME% %CODE%
pause
goto start

:balance
call "\\gus\pawprints\files\viewbal.bat"
goto start

:create
cls
echo.
echo.
echo This function is not currently being used.
pause
goto start

:config
cls
echo.
echo.
echo This function is not currently being used.
pause
goto start

:error
echo.
echo There was an error!
echo.

:configure_dcode_webclient
d:\inetroot\cgi-bin\DCode.exe config
goto start

:end_all


