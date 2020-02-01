net stop spooler /y
del %systemroot%\system32\spool\printers\*.shd
del %systemroot%\system32\spool\printers\*.spl
%systemroot%\system32\shutdown.exe /r /f

pause
