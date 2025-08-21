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

command_files_to_check="${@:2}"
command_args=$1
command_to_run="${exec_command} analyse  ${command_args}"

echo -e "${bldwht}Running command ${txtgrn} ${exec_command} analyse  ${txtrst}"
hr
command_result=`eval $command_to_run`
if [[ $command_result =~ ERROR ]]
then
    hr
    echo -en "${bldmag}Errors detected by ${title}... ${txtrst} \n"
    hr
    echo "$command_result"
    exit 1
fi

exit 0
