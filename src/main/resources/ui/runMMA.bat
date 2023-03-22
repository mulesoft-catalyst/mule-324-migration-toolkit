@echo off
setlocal ENABLEDELAYEDEXPANSION

rem This script executes the MMA on all Mule 3 projects in a particular folder / directory
rem and aggregates all the JSON report outputs into a ZIP file for the purposes of estimation

rem Set defaults
set workingDir=%TEMP%\m3tom4estimator
set cleanupM4Dir=true
set outputZip=results-%date:~6,4%%date:~3,2%%date:~0,2%%time:~0,2%%time:~3,2%%date:~6,2%.zip
set version=4.4.0
rmdir /q /s %workingDir% 1>NUL 2>NUL

rem Check input parameters
:getopts
if /I "%1"=="-m" (set mma=%2& shift) else (if /I "%1"=="-p" (set mule3Project=%2& shift) else (if /I "%1"=="-v" (set version=%2& shift) else (if /I "%1"=="-o" (set workingDir=%2& set cleanupM4Dir=false& shift) else (if /I "%1"=="-d" (set mule3DomainProject=%2& shift) else (echo Unknown option: %1& goto :usage)))))
shift
if not "%1" == "" goto :getopts

if "%mma%" == "" echo Mandatory option missing: -m& goto :usage
if "%mule3Project%" == "" echo Mandatory option missing: -p& goto :usage

echo ------------------------------------------------------------------------------------------------------------
echo MMA Path - %mma%
echo Mule 3 Project Path (Input) - %mule3Project%
echo Mule 3 Domain Project Path - %mule3DomainProject%
echo Mule 4 Project Path (Output) - %workingDir%
echo Mule 4 Version - %version%
echo ------------------------------------------------------------------------------------------------------------
echo %date:~6,4%-%date:~3,2%-%date:~0,2% %time%:Start executing MMA for all sub directories

echo ------------------------------------------------------------------------------------------------------------ >> runMMA-Output.log
echo MMA Path - %mma% >> runMMA-Output.log
echo Mule 3 Project Path (Input) - %mule3Project% >> runMMA-Output.log
echo Mule 3 Domain Project Path - %mule3DomainProject% >> runMMA-Output.log
echo Mule 4 Project Path (Output) - %workingDir% >> runMMA-Output.log
echo Mule 4 Version - %version% >> runMMA-Output.log
echo ------------------------------------------------------------------------------------------------------------ >> runMMA-Output.log
echo %date:~6,4%-%date:~3,2%-%date:~0,2% %time%:Start executing MMA for all sub directories >> runMMA-Output.log

for /D %%d in (%mule3Project%\*) do (
	if exist "%%d" (
		for /F "delims=" %%i in ("%%d") do set m3ProjName=%%~ni
		echo %date:~6,4%-%date:~3,2%-%date:~0,2% %time%:Executing MMA for !m3ProjName!
		echo %date:~6,4%-%date:~3,2%-%date:~0,2% %time%:Executing MMA for !m3ProjName! >> runMMA-Output.log
		if  "%mule3DomainProject%" == "" (
			java -jar %mma% -projectBasePath "%%d" -destinationProjectBasePath "%workingDir%\!m3ProjName!" -muleVersion %version% -jsonReport >> runMMA-Output.log
		) else (
			java -jar %mma% -projectBasePath "%%d" -destinationProjectBasePath "%workingDir%\!m3ProjName!" -muleVersion %version% -jsonReport -parentDomainBasePath "%mule3DomainProject%" >> runMMA-Output.log
		)
		copy "%workingDir%\!m3ProjName!\report\report.json" "%workingDir%\report-!m3ProjName!.json" >> runMMA-Output.log
	)
)

echo %date:~6,4%-%date:~3,2%-%date:~0,2% %time%:Aggregating and compressing all MMA reports to %outputZip%
echo %date:~6,4%-%date:~3,2%-%date:~0,2% %time%:Aggregating and compressing all MMA reports to %outputZip% >> runMMA-Output.log
tar -a -c -f %outputZip% -C %workingDir% "report-*.json"  >> runMMA-Output.log

if %cleanupM4Dir% == true (
	rmdir /q /s %workingDir% 1>NUL 2>NUL
)

echo %date:~6,4%-%date:~3,2%-%date:~0,2% %time%:End executing MMA for all sub directories
echo ------------------------------------------------------------------------------------------------------------

echo %date:~6,4%-%date:~3,2%-%date:~0,2% %time%:End executing MMA for all sub directories >> runMMA-Output.log
echo ------------------------------------------------------------------------------------------------------------ >> runMMA-Output.log

goto :end

rem Show script usage
:usage
	echo Usage: runMMA.bat -m "MMA Path" -p "Mule 3 Projects Path" [-d "Mule 3 Domain Projects Path"] [-o "Mule 4 Output Projects Path"] [-v "Mule 4 version"]
	echo -m: (Required) Full path of the Mule Migration Assistant (MMA) compiled jar with version
	echo -p: (Required) Full path of the directory where all Mule 3 projects are located
	echo -d: (Optional) Full path of the Mule 3 Domain Project. This is an optional parameter but it MUST be passed if the Mule 3 projects uses a domain or else the MMA will fail to migrate the application
	echo -o: (Optional) Full path of the directory where all Mule 4 projects will be created by the MMA. If not provided, the script will create a temporary output folder and cleanup any Mule 4 Projects after the script completes processing
	echo -v: (Optional) Mule Runtime Semantic version eg: 4.4.0 to which the project will be migrated. Default is 4.4.0
	goto :end

:end
