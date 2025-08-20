#!/usr/bin/env bash
################################################################################
#
# Bash PHPStan
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

# DEBUG: Run diagnose first
echo -e "${bldwht}Running PHPStan diagnose...${txtrst}"
hr
diagnose_result=`${exec_command} diagnose 2>&1`
echo "$diagnose_result"
hr

# DEBUG: Check PHP and SoapClient
echo -e "${bldwht}Checking PHP environment...${txtrst}"
php_version=`php -v | head -1`
echo "PHP Version: $php_version"
soap_check=`php -r "echo class_exists('SoapClient') ? 'SoapClient: EXISTS' : 'SoapClient: NOT FOUND';"`
echo "$soap_check"
hr

# DEBUG: Show exact command being run
command_files_to_check="${@:2}"
command_args=$1
command_to_run="${exec_command} analyse -vvv --no-progress ${command_args} ${command_files_to_check}"
echo -e "${bldwht}Running command ${txtgrn} ${command_to_run} ${txtrst}"
hr

# Run the actual command
command_result=`eval $command_to_run 2>&1`
exit_code=$?

# DEBUG: Always show the output for debugging
echo -e "${bldwht}PHPStan output:${txtrst}"
echo "$command_result"
hr

# Original logic
if [[ $command_result =~ ERROR ]]
then
    echo -en "${bldmag}Errors detected by ${title}... ${txtrst} \n"
    exit 1
fi

exit $exit_code
