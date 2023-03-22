#!/bin/bash
# This script executes the MMA on all Mule 3 projects in a particular folder / directory
# and aggregates all the JSON report outputs into a ZIP file for the purposes of estimation

# Show script usage
usage() {
	echo "Usage: $0 -m <MMA Path> -p <Mule 3 Projects Path> [-d <Mule 3 Domain Projects Path>] [-o <Mule 4 Output Projects Path>] [-v <Mule 4 version>]"
	echo "-m: (Required) Full path of the Mule Migration Assistant (MMA) compiled jar with version"
	echo "-p: (Required) Full path of the directory where all Mule 3 projects are located"
	echo "-d: (Optional) Full path of the Mule 3 Domain Project. This is an optional parameter but it MUST be passed if the Mule 3 projects uses a domain or else the MMA will fail to migrate the application"
	echo "-o: (Optional) Full path of the directory where all Mule 4 projects will be created by the MMA. If not provided, the script will create a temporary output folder and cleanup any Mule 4 Projects after the script completes processing"
	echo "-v: (Optional) Mule Runtime Semantic version eg: 4.4.0 to which the project will be migrated. Default is 4.4.0"
	exit 1;
}

# Set defaults
workingDir=/tmp/m3tom4estimator
cleanupM4Dir=true
outputZip=results-$(date +"%Y%m%d%H%M%S").zip
version=4.4.0
rm -fr ${workingDir} > /dev/null 2>&1

# Check input parameters
while getopts ":m:p:v:o:d:" arg; do
  case "${arg}" in
    m)
			mma=${OPTARG}
      ;;
    p)
      mule3Project=${OPTARG}
      ;;
    d)
      mule3DomainProject=${OPTARG}
      ;;
		v)
			version=${OPTARG}
      ;;
		o)
			workingDir=${OPTARG}
			cleanupM4Dir=false
      ;;
		*)
			echo "Unknown option:" ${OPTARG}
			usage
			;;
  esac
done

if [ -z "${mma}" ]; then
	echo "Mandatory option missing: -m"
	usage
fi

if [ -z "${mule3Project}" ]; then
	echo "Mandatory option missing: -p"
	usage
fi

echo "------------------------------------------------------------------------------------------------------------" | tee -a runMMA-Output.log
echo "MMA Path -" ${mma} | tee -a runMMA-Output.log
echo "Mule 3 Project Path (Input) -" ${mule3Project} | tee -a runMMA-Output.log
echo "Mule 3 Domain Project Path -" ${mule3DomainProject} | tee -a runMMA-Output.log
echo "Mule 4 Project Path (Output) -" ${workingDir} | tee -a runMMA-Output.log
echo "Mule 4 Version -" ${version} | tee -a runMMA-Output.log
echo "------------------------------------------------------------------------------------------------------------" | tee -a runMMA-Output.log
echo "$(date):Start executing MMA for all sub directories" | tee -a runMMA-Output.log
for dir in ${mule3Project}/*/ ; do
	if [ -d "${dir}" ]; then
		m3ProjName=$(basename ${dir})
		echo "$(date):Executing MMA for "${m3ProjName} | tee -a runMMA-Output.log
		if [ -d "${mule3DomainProject}" ]; then
			java -jar ${mma} -projectBasePath "${dir}" -destinationProjectBasePath "${workingDir}/${m3ProjName}" -muleVersion ${version} -jsonReport -parentDomainBasePath "${mule3DomainProject}" >> runMMA-Output.log
		else 
			java -jar ${mma} -projectBasePath "${dir}" -destinationProjectBasePath "${workingDir}/${m3ProjName}" -muleVersion ${version} -jsonReport >> runMMA-Output.log
		fi 
		cp "${workingDir}/${m3ProjName}/report/report.json" "${workingDir}/report-${m3ProjName}.json" >> runMMA-Output.log 2>&1
	fi
done
echo "$(date):Aggregating and compressing all MMA reports to "${outputZip} | tee -a runMMA-Output.log
zip -r -j ${outputZip} ${workingDir}/report-*.json >> runMMA-Output.log 2>&1
if ${cleanupM4Dir}; then
	rm -fr ${workingDir} > /dev/null 2>&1
fi
echo "$(date):End executing MMA for all sub directories" | tee -a runMMA-Output.log
echo "------------------------------------------------------------------------------------------------------------" | tee -a runMMA-Output.log
exit 0
