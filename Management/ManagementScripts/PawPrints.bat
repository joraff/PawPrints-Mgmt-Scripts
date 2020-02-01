@rem Purpose: Account Managment of PawPrints system at Baylor University
@rem Original Creation Date: Dec 29 2003
@rem Revised for New Server: Dec 19 2007

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
echo       a )  Configure WebClient Settings
echo       b )  Configure DCode WebClient settings
echo       c )  Add Pages to Accounts from Text File
echo       d )  Run the Bill
echo       e )  Exit
echo.      
echo.
c:\PawPrintsManagement\ManagementScripts\Tools\choice.com /cabcde /n
if errorlevel 5  goto :end_all
if errorlevel 4  goto :runthebill
if errorlevel 3  goto :multiadd
if errorlevel 2  goto :Dcode
if errorlevel 1  goto :webClient
goto error

:webClient
c:\inetpub\cgi-bin\webclient.exe config
pause
goto start

:DCode
c:\inetpub\cgi-bin\DCode.exe config
pause
goto start

:multiadd
c:\PawPrintsManagement\ManagementScripts\multiadd.bat
pause
goto start

:runthebill
c:\PawPrintsManagement\ManagementScripts\runthebill.bat
pause
goto start

:end_all