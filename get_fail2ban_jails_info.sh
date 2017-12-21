#!/bin/bash
# Get fail2ban jails to log file.
# Author: Alexandr "zEvilz" Emshanov
# License: MIT

SHOW_JAILS_INFO=0
F2B_LOG_FILE="<full_path_to_log_file>"

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
