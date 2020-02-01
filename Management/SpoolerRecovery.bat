@echo off
net stop spooler
net stop pcounterprint
net start spooler
net start pcounterprint