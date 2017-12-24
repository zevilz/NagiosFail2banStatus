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

Put [check_fail2ban.sh](https://github.com/zevilz/NagiosFail2banStatus/blob/master/check_fail2ban.sh) to nagios plugins directory (usually `/usr/lib*/nagios/plugins`). Than make file executable (`chmod +x check_fail2ban.sh`).

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

By default without this parameters you can get only status on fail2ban (running/not running). Log file is required for show jails and jails info because the nagios user does not have the rights to access the fail2ban client. Put [get_fail2ban_jails_info.sh](https://github.com/zevilz/NagiosFail2banStatus/blob/master/get_fail2ban_jails_info.sh) in any directory if you want to get jails info.

Than add script to cron
```bash
*/1 * * * * bash <full_path_to_script> -p <full_path_to_log_file>
```

Use parameter `-i (--show-jails-info)` if you want to show info about for each jail
```bash
*/1 * * * * bash <full_path_to_script> -p <full_path_to_log_file> -i
```

Script creates/updates log file in specified path and make it readable only for users in `nagios` group and for user `nagios`.

## Changelog
- 23.12.2017 - 1.0.1 - added parameters to script `get_fail2ban_jails_info.sh` instead of editing inner variables
- 21.12.2017 - 1.0.0 - released
