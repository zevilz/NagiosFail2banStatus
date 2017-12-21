# NagiosFail2banStatus

Nagios plugin for check fail2ban status and jails. Supports directly usage and Nagios/Icinga usage.

## Options

- `-h (--help)` - Shows help message.
- `-j (--show-jails)` - Shows active jails. Uses special log file with fail2ban status if Nagios/Icinga usage enabled.
- `-i (--show-jails-info)` - Shows jails info. Only for directly usage.
- `-n (--nagios)` - Enable Nagios/Icinga usage. Showing jails info requiring use log file with fail2ban status.
- `-p (--log-path)` - Specify path to log file with fail2ban status. Only for Nagios/Icinga usage (usage: `-p <path> | --log-path=<path>`).

## Usage

Notice: curent user must be root or user with sudo access.

Put plugin file to nagios plugins directory (usually /usr/lib*/nagios/plugins). Than make file executable (`chmod +x check_fail2ban.sh`).

### Directly usage

Show only status
```bash
./check_fail2ban.sh
```

Show active jails
```bash
./check_fail2ban.sh -j
```

Show active jails and their info
```bash
./check_fail2ban.sh -j -i
```

### Nagios/Icinga usage

Add following check command object to your commands file
```bash
object CheckCommand "fail2ban" {
		import "plugin-check-command"
		command = [ PluginDir + "/check_fail2ban.sh" ]
		arguments = {
				"-n" = {}
				"-j" = {
						set_if = "$show_jails$"
				}
				"-p" = {
						value = "$log_path$"
						set_if = "$show_jails$"
				}
		}
}
```

Than add service definition to your services with `check_command = "fail2ban"`.

Supported vars:
- `show_jails` - Shows active jails. Set `1` to activate.
- `log_path` - Sets full path to log file with fail2ban status. Required if `show_jails` set to `1`.

By default without this parameters you can get only status on fail2ban (running/not running). Log file is required for show jails and jails info because the nagios user does not have the rights to access the fail2ban client. If you want to get this info make folowing script in any directory
```bash
#!/bin/bash

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
```

Set `SHOW_JAILS_INFO` to `1` if you want to show info about for each jail.

Than add script to cron
```bash
*/1 * * * * bash <full_path_to_script>
```

Script creates/updates log file in specified path and make it readable only for users in `nagios` group and for user `nagios`.

## Changelog
- 21.12.2017 - 1.0.0 - released
