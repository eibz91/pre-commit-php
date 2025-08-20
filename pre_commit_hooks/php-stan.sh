#!/usr/bin/env bash
################################################################################
#
# Bash PHPStan - Version 1.2 with Enhanced Debugging
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
vendor_command="vendor/bin/phpstan"
global_command="phpstan"
# Print a welcome and locate the exec for this tool
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/helpers/colors.sh
source $DIR/helpers/formatters.sh
source $DIR/helpers/welcome.sh
source $DIR/helpers/locate.sh

echo -e "${bldgrn}=== PHPStan Debug Script v1.2 ===${txtrst}"
hr

# DEBUG: Show which PHPStan is being used
echo -e "${bldwht}PHPStan location and version:${txtrst}"
which phpstan || echo "Global phpstan not found"
echo "Using: ${exec_command}"
${exec_command} --version
echo "Full path: $(readlink -f ${exec_command} 2>/dev/null || echo ${exec_command})"
hr

# DEBUG: Show working directory and config
echo -e "${bldwht}Working directory:${txtrst}"
pwd
echo -e "${bldwht}Git info:${txtrst}"
git rev-parse HEAD 2>/dev/null || echo "Not in git repo"
git status --porcelain 2>/dev/null | head -5
hr

# DEBUG: Config files
echo -e "${bldwht}Looking for phpstan config files:${txtrst}"
find . -name "phpstan*.neon" -type f 2>/dev/null | head -10
echo -e "${bldwht}Content of phpstan.neon:${txtrst}"
if [ -f "phpstan.neon" ]; then
    cat phpstan.neon
else
    echo "phpstan.neon not found in current directory"
    echo "Checking parent directories..."
    find .. -name "phpstan.neon" -type f 2>/dev/null | head -5
fi
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
echo -e "${bldwht}Clearing PHPStan cache:${txtrst}"
${exec_command} clear-result-cache 2>&1 || echo "Could not clear cache"
# Also try to find and clear cache directory
echo "Looking for cache directories:"
find ~/.phpstan ~/.cache -name "*phpstan*" -type d 2>/dev/null | head -5
hr

# DEBUG: PHP Environment
echo -e "${bldwht}PHP Environment:${txtrst}"
php -v
echo -e "\nPHP Extensions:"
php -m | grep -E "(soap|Soap|SOAP)" || echo "SOAP not found in php -m"
echo -e "\nPHP ini files:"
php --ini | head -5
hr

# DEBUG: Check file encoding and content
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
command_to_run="${exec_command} analyse --no-progress ${command_args} ${command_files_to_check}"
echo -e "${bldwht}Full command:${txtrst}"
echo "${command_to_run}"
hr

# Run the actual command
echo -e "${bldwht}Running PHPStan...${txtrst}"
command_result=`eval $command_to_run 2>&1`
exit_code=$?

# DEBUG: Always show the output for debugging
echo -e "${bldwht}PHPStan output:${txtrst}"
echo "$command_result"
echo -e "\nExit code: $exit_code"
hr

# Original logic
if [[ $command_result =~ ERROR ]]
then
    echo -en "${bldmag}Errors detected by ${title}... ${txtrst} \n"
    echo "String 'ERROR' found in output"
    exit 1
fi

echo -e "${bldgrn}No errors detected${txtrst}"
exit $exit_code
