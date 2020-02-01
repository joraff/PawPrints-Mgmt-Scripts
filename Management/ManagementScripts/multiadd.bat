echo.
echo.
echo      Add amount to users' balance, where users are listed in a text file
echo.
echo.
set /p AMOUNT="Please enter a deposit amount: "
set /p COMMENT="Please enter a comment: "
set /p FILEPATH="Please enter the full pathname of the text file to process: "
for /f %%U in (%FILEPATH%) do (
	"c:\Program Files\Pcounter for NT\NT\account.exe" DEPOSIT %%U %AMOUNT% %COMMENT%
	if errorlevel=1 echo %%U% >> c:\errorlog.txt)