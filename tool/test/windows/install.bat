@echo off
rem Run by dockur at the end of the unattended install of the golden VM
rem (this folder is mounted as /oem and copied to C:\OEM).
powershell -NoProfile -ExecutionPolicy Bypass -File C:\OEM\ssh.ps1 > C:\OEM\ssh.log 2>&1
