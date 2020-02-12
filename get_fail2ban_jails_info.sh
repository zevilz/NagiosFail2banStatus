#!/bin/bash
# Nagios plugin for check fail2ban status.
# This script for create/update log file.
# URL: https://github.com/zevilz/NagiosFail2banStatus
# Author: Alexandr "zEvilz" Emshanov
# License: MIT
# Version: 1.0.2

checkLogFilePath()
{
	if [[ -z "$F2B_LOG_FILE" || "$F2B_LOG_FILE" =~ ^-.*$ ]]; then
		echo "ERROR! Path to log file not set."
		exit 2
	else
		if [[ "$F2B_LOG_FILE" =~ ^-?.*\/$ ]]
		then
			echo "ERROR! Log filename not set in given path."
			exit 2
		fi
	fi
}

SHOW_JAILS_INFO=0
F2B_LOG_FILE=""

while [ 1 ] ; do
	if [ "${1#--log-path=}" != "$1" ] ; then
		F2B_LOG_FILE="${1#--log-path=}"
	elif [ "$1" = "-p" ] ; then
		shift ; F2B_LOG_FILE="$1"

	elif [[ "$1" = "--show-jails-info" || "$1" = "-i" ]] ; then
		SHOW_JAILS_INFO=1

	elif [ -z "$1" ] ; then
		break
	else
		echo "ERROR! Unknown key detected!"
		exit 2
	fi
	shift
done

checkLogFilePath

JAILS=`fail2ban-client status 2>/dev/null | grep "Jail list" | sed -e 's/^[^:]\+:[ \t]\+//' | sed 's/,//g'`

if ! [ -z "$JAILS" ]; then
	echo "Fail2ban OK: active jails - $JAILS" > "$F2B_LOG_FILE"
	if [ $SHOW_JAILS_INFO -eq 1 ]; then
		echo >> "$F2B_LOG_FILE"
		for JAIL in $JAILS; do
			fail2ban-client status $JAIL | sed 's/[|`]*//g' >> "$F2B_LOG_FILE"
		done
	fi
else
	echo "" > "$F2B_LOG_FILE"
fi

chmod 700 "$F2B_LOG_FILE"
chown nagios:nagios "$F2B_LOG_FILE"
