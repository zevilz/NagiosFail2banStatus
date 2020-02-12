#!/bin/bash
# Nagios plugin for check fail2ban status.
# URL: https://github.com/zevilz/NagiosFail2banStatus
# Author: Alexandr "zEvilz" Emshanov
# License: MIT
# Version: 1.0.1

usage()
{
	echo
	echo "Usage: bash $0 [options]"
	echo
	echo "Nagios plugin for check fail2ban status."
	echo
	echo "Options:"
	echo
	echo "    -h, --help              Shows this help. Only for directly usage."
	echo
	echo "    -j, --show-jails        Shows active jails. Uses special log file with "
	echo "                            fail2ban status if Nagios/Icinga usage enabled."
	echo
	echo "    -i, --show-jails-info   Shows jails info. Only for directly usage."
	echo
	echo "    -n, --nagios            Enable Nagios/Icinga usage. Showing jails info "
	echo "                            requiring use log file with fail2ban status."
	echo
	echo "    -p <path>,              Specify path to log file with fail2ban status. "
	echo "    --log-path=<path>       Only for Nagios/Icinga usage."
	echo
}
checkF2bProcess()
{
	F2B_CHECK_PROCCESS=`ps -e | grep 'fail2ban\|f2b'`
	if [ -z "$F2B_CHECK_PROCCESS" ]; then
		echo "ERROR! Fail2ban not running."
		exit 2
	fi
}
checkLog()
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
	if ! [ -f "$F2B_LOG_FILE" ]; then
		echo "ERROR! Log file not found ($F2B_LOG_FILE)."
		exit 2
	fi
}
checkParams()
{
	if [ $NAGIOS_USAGE -eq 1 ]; then
		if [ $SHOW_JAILS_INFO -eq 1 ]; then
			echo "ERROR! It is impossible to use option -i(--show-jails-info) with enabled Nagios/Icinga usage."
			exit 2
		fi
		if ! [ $HELP -eq 0 ]; then
			echo "ERROR! It is impossible to use option -h(--help) with enabled Nagios/Icinga usage."
			exit 2
		fi
		if [[ $SHOW_JAILS -eq 1 && -z "$F2B_LOG_FILE" ]]; then
			echo "ERROR! Path to log file not set."
			exit 2
		fi
	fi
}

NAGIOS_USAGE=0
SHOW_JAILS=0
SHOW_JAILS_INFO=0
HELP=0
F2B_LOG_FILE=""

while [ 1 ] ; do
	if [ "${1#--log-path=}" != "$1" ] ; then
		F2B_LOG_FILE="${1#--log-path=}"
	elif [ "$1" = "-p" ] ; then
		shift ; F2B_LOG_FILE="$1"

	elif [[ "$1" = "--help" || "$1" = "-h" ]] ; then
		HELP=1

	elif [[ "$1" = "--nagios" || "$1" = "-n" ]] ; then
		NAGIOS_USAGE=1

	elif [[ "$1" = "--show-jails" || "$1" = "-j" ]] ; then
		SHOW_JAILS=1

	elif [[ "$1" = "--show-jails-info" || "$1" = "-i" ]] ; then
		SHOW_JAILS_INFO=1

	elif [ -z "$1" ] ; then
		break
	else
		echo "ERROR! Unknown key detected!"
		usage
		exit 2
	fi
	shift
done

if [[ $HELP == 1 ]]
then
	usage
	exit 0
fi

if ! [ -z "$F2B_LOG_FILE" ]; then
	checkLog
fi

checkParams

if [ $SHOW_JAILS -eq 0 ]; then
	checkF2bProcess
	echo "Fail2ban OK."
	exit 0
else
	if [ $NAGIOS_USAGE -eq 0 ]; then
		checkF2bProcess
		JAILS=`fail2ban-client status | grep "Jail list" | sed -e 's/^[^:]\+:[ \t]\+//' | sed 's/,//g'`
		echo "Fail2ban OK: active jails - $JAILS"
		if [ $SHOW_JAILS_INFO -eq 1 ]; then
			echo
			for JAIL in $JAILS; do
				fail2ban-client status $JAIL | sed 's/[|`]*//g'
			done
		fi
		exit 0
	else
		F2B_STATUS=`cat "$F2B_LOG_FILE"`
		if ! [ -z "$F2B_STATUS" ]; then
			echo "$F2B_STATUS"
			exit 0
		else
			echo "ERROR! Fail2ban not running."
			exit 2
		fi
	fi
fi
