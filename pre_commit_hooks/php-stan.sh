#!/usr/bin/env bash
################################################################################
#
# Bash PHPStan - Version 1.5 with Detailed Timing and SOAP Validation
#
# This script fails if the PHPStan output has the word "ERROR" in it.
#
# Exit 0 if no errors found
# Exit 1 if errors were found
#
# Requires
# - php
#
# Arguments
# See: https://phpstan.org/user-guide/command-line-usage
#
################################################################################
# Plugin title
title="PHPStan"
# Possible command names of this tool
local_command="phpstan.phar"
vendor_command="api/v2/vendor/bin/phpstan"  # Changed to use api/v2/vendor
global_command="phpstan"

# Start timing
script_start=$(date +%s)
echo "=== SCRIPT STARTED AT: $(date) ==="

df_output=$(df -T)
echo "Resultado de df -T:"
echo "$df_output"

# Print a welcome and locate the exec for this tool
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/helpers/colors.sh
source $DIR/helpers/formatters.sh
source $DIR/helpers/welcome.sh

echo "Time before locate: $(date)"
locate_start=$(date +%s)
source $DIR/helpers/locate.sh
locate_end=$(date +%s)
echo "Locate took: $((locate_end - locate_start)) seconds"

echo -e "${bldgrn}=== PHPStan Debug Script v1.5 ===${txtrst}"
hr

# DEBUG: Show which PHPStan is being used
echo "Time before version check: $(date)"
version_start=$(date +%s)
echo -e "${bldwht}PHPStan location and version:${txtrst}"
which phpstan || echo "Global phpstan not found"
echo "Using: ${exec_command}"
${exec_command} --version
echo "Full path: $(readlink -f ${exec_command} 2>/dev/null || echo ${exec_command})"
version_end=$(date +%s)
echo "Version check took: $((version_end - version_start)) seconds"
hr

# DEBUG: Show working directory and config
echo -e "${bldwht}Working directory:${txtrst}"
echo "Current directory: $(pwd)"
echo "Script directory: $DIR"
echo -e "${bldwht}Git info:${txtrst}"
git rev-parse HEAD 2>/dev/null || echo "Not in git repo"
git status --porcelain 2>/dev/null | head -5
hr

# DEBUG: Config files - Show content of ALL found neon files
echo "Time before config search: $(date)"
config_start=$(date +%s)
echo -e "${bldwht}Looking for phpstan config files and their contents:${txtrst}"
neon_files=$(find . \( -name "phpstan*.neon" -o -name "phpstan-config.neon" \) -type f 2>/dev/null | head -10)
if [ -n "$neon_files" ]; then
    for neon_file in $neon_files; do
        echo -e "\n${txtgrn}=== Content of $neon_file ===${txtrst}"
        cat "$neon_file" | head -30
        echo -e "${txtgrn}=== End of $neon_file ===${txtrst}\n"
    done
else
    echo "No phpstan*.neon or phpstan-config.neon files found"
fi
config_end=$(date +%s)
echo "Config search took: $((config_end - config_start)) seconds"
hr

# DEBUG: Test which config file PHPStan will actually use
echo -e "${bldwht}Testing which config file PHPStan will use:${txtrst}"
${exec_command} analyse --help | grep -A2 "configuration" || echo "Could not get help for configuration"
echo ""
echo "PHPStan says it's using:"
${exec_command} analyse --configuration=phpstan-config.neon --debug 2>&1 | head -20 | grep -E "(Configuration|Using|Loading|Note:)" || echo "No configuration info found"
hr

# DEBUG: Composer info
echo -e "${bldwht}Composer PHPStan info:${txtrst}"
if [ -f "composer.json" ]; then
    grep -A2 -B2 "phpstan" composer.json 2>/dev/null || echo "PHPStan not found in composer.json"
fi
if [ -f "composer.lock" ]; then
    echo "From composer.lock:"
    grep -A5 '"name": "phpstan/phpstan"' composer.lock 2>/dev/null | grep version || echo "Version not found"
fi
hr

# DEBUG: Clear cache
echo "Time before cache clear: $(date)"
cache_start=$(date +%s)
echo -e "${bldwht}Clearing PHPStan cache:${txtrst}"
${exec_command} clear-result-cache 2>&1 || echo "Could not clear cache"
# Also try to find and clear cache directory
echo "Looking for cache directories:"
find ~/.phpstan ~/.cache -name "*phpstan*" -type d 2>/dev/null | head -5
cache_end=$(date +%s)
echo "Cache clear took: $((cache_end - cache_start)) seconds"
hr

# DEBUG: PHP Environment with detailed SOAP check
echo -e "${bldwht}PHP Environment:${txtrst}"
php -v
echo -e "\nPHP Extensions:"
php -m | grep -E "(soap|Soap|SOAP)" || echo "SOAP not found in php -m"

echo -e "\n${bldwht}Detailed SOAP Extension Check:${txtrst}"
php -r "
echo 'SOAP extension loaded: ' . (extension_loaded('soap') ? 'YES' : 'NO') . PHP_EOL;
echo 'SoapClient class exists: ' . (class_exists('SoapClient') ? 'YES' : 'NO') . PHP_EOL;
if (class_exists('SoapClient')) {
    \$reflection = new ReflectionClass('SoapClient');
    echo 'SoapClient file: ' . \$reflection->getFileName() . PHP_EOL;
    echo 'SoapClient methods count: ' . count(\$reflection->getMethods()) . PHP_EOL;
} else {
    echo 'Cannot reflect on SoapClient - class does not exist' . PHP_EOL;
}
"

echo -e "\nSOAP configuration from php.ini:"
php -i | grep -A5 -B5 soap || echo "No SOAP configuration found"

echo -e "\nPHP ini files:"
php --ini | head -5
hr

# DEBUG: Check file encoding and content
echo "Time before file analysis: $(date)"
file_start=$(date +%s)
echo -e "${bldwht}File analysis for stpmex.php:${txtrst}"
if [ -f "api/v2/helpers/stpmex/stpmex.php" ]; then
    echo "File exists: YES"
    echo "File size: $(stat -f%z api/v2/helpers/stpmex/stpmex.php 2>/dev/null || stat -c%s api/v2/helpers/stpmex/stpmex.php 2>/dev/null)"
    echo "File encoding: $(file -b api/v2/helpers/stpmex/stpmex.php)"
    echo "MD5: $(md5sum api/v2/helpers/stpmex/stpmex.php 2>/dev/null || md5 api/v2/helpers/stpmex/stpmex.php 2>/dev/null)"
    echo -e "\nLine 1480-1485:"
    sed -n '1480,1485p' api/v2/helpers/stpmex/stpmex.php | cat -n
    echo -e "\nHex dump of line 1481:"
    sed -n '1481p' api/v2/helpers/stpmex/stpmex.php | xxd -l 60
    echo -e "\nSearching for 'soapclient' (case-insensitive):"
    grep -in "soapclient" api/v2/helpers/stpmex/stpmex.php 2>/dev/null | head -5 || echo "No 'soapclient' found"
    echo -e "\nSearching for 'SoapClient':"
    grep -n "SoapClient" api/v2/helpers/stpmex/stpmex.php 2>/dev/null | head -5 || echo "No 'SoapClient' found"
else
    echo "File NOT FOUND at api/v2/helpers/stpmex/stpmex.php"
    echo "Looking for stpmex.php in other locations:"
    find . -name "stpmex.php" -type f 2>/dev/null
fi
file_end=$(date +%s)
echo "File analysis took: $((file_end - file_start)) seconds"
hr

# DEBUG: Environment variables
echo -e "${bldwht}Relevant environment variables:${txtrst}"
env | grep -E "(PHP|COMPOSER|PATH)" | grep -v "SECRET" | head -10
hr

# DEBUG: Show exact command being run
command_files_to_check="${@:2}"
command_args=$1
echo -e "${bldwht}Command construction:${txtrst}"
echo "exec_command: ${exec_command}"
echo "command_args: ${command_args}"
echo "files_to_check: ${command_files_to_check}"

# Replace any phpstan.neon references with phpstan-config.neon
command_args=$(echo "$command_args" | sed 's/phpstan\.neon/phpstan-config.neon/g')
command_files_to_check=$(echo "$command_files_to_check" | sed 's/phpstan\.neon/phpstan-config.neon/g')

# If no --configuration is present, add it
if [[ ! "$command_args" =~ "--configuration" ]] && [[ ! "$command_files_to_check" =~ "--configuration" ]]; then
    command_args="$command_args --configuration=phpstan-config.neon"
fi

# Remove --no-progress and add more verbosity
# Also ensure we're using api/v2/vendor/bin/phpstan explicitly
if [[ "${exec_command}" != "api/v2/vendor/bin/phpstan" ]]; then
    echo "Forcing use of api/v2/vendor/bin/phpstan"
    exec_command="api/v2/vendor/bin/phpstan"
fi

command_to_run="${exec_command} analyse ${command_args}"
echo -e "${bldwht}Full command:${txtrst}"
echo "${command_to_run}"
hr

# Run the actual command with extra verbosity to see each file
echo -e "${bldwht}Running PHPStan with maximum verbosity...${txtrst}"
echo "Starting PHPStan at: $(date)"
phpstan_start=$(date +%s)

# Capture the full output
echo "Executing: $command_to_run"
command_result=`eval $command_to_run -vvv 2>&1`
exit_code=$?

phpstan_end=$(date +%s)
echo "Finished PHPStan at: $(date)"
echo "PHPStan analysis took: $((phpstan_end - phpstan_start)) seconds"

# DEBUG: Always show the output for debugging
echo -e "${bldwht}PHPStan output:${txtrst}"
echo "$command_result"

# Analyze what files were processed
echo -e "\n${bldwht}Files analyzed count:${txtrst}"
echo "$command_result" | grep -E "^/" | wc -l

echo -e "\n${bldwht}Unique files analyzed:${txtrst}"
echo "$command_result" | grep -E "^/" | sort | uniq | head -20

echo -e "\n${bldwht}Memory consumption per file:${txtrst}"
echo "$command_result" | grep -E "consumed.*MB" | head -10

echo -e "\nExit code: $exit_code"
hr

# Original logic
if [[ $command_result =~ ERROR ]]
then
    echo -en "${bldmag}Errors detected by ${title}... ${txtrst} \n"
    echo "String 'ERROR' found in output"
    exit_result=1
else
    echo -e "${bldgrn}No errors detected${txtrst}"
    exit_result=$exit_code
fi

# Final timing summary
script_end=$(date +%s)
total_time=$((script_end - script_start))
echo -e "\n${bldwht}=== TIMING SUMMARY ===${txtrst}"
echo "Script started: $(date -d @$script_start 2>/dev/null || date -r $script_start)"
echo "Script ended: $(date)"
echo "Total script time: ${total_time} seconds"
echo "Time breakdown:"
echo "  - Locate: $((locate_end - locate_start))s"
echo "  - Version check: $((version_end - version_start))s"
echo "  - Config search: $((config_end - config_start))s"
echo "  - Cache clear: $((cache_end - cache_start))s"
echo "  - File analysis: $((file_end - file_start))s"
echo "  - PHPStan analysis: $((phpstan_end - phpstan_start))s"
echo "  - Other operations: $((total_time - (locate_end - locate_start) - (version_end - version_start) - (config_end - config_start) - (cache_end - cache_start) - (file_end - file_start) - (phpstan_end - phpstan_start)))s"

exit $exit_result
