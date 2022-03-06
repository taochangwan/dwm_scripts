#!/bin/bash
# This function parses /proc/net/dev file searching for a line containing $interface data.
# Within that line, the first and ninth numbers after ':' are respectively the received and transmited bytes.
function get_bytes {
	# Find active network interface
	interface=$(ip route get 8.8.8.8 2>/dev/null| awk '{print $5}')
	line=$(grep $interface /proc/net/dev | cut -d ':' -f 2 | awk '{print "received_bytes="$1, "transmitted_bytes="$9}')
	eval $line
	now=$(date +%s%N)
}

# Function which calculates the speed using actual and old byte number.
# Speed is shown in KByte per second when greater or equal than 1 KByte per second.
# This function should be called each second.

function get_velocity {
	value=$1
	old_value=$2
	now=$3

	timediff=$(($now - $old_time))
	velKB=$(echo "1000000000*($value-$old_value)/1024/$timediff" | bc)
	if test "$velKB" -gt 1024
	then
		echo $(echo "scale=2; $velKB/1024" | bc)MB/s
	else
		echo ${velKB}KB/s
	fi
}

# Get initial values
get_bytes
old_received_bytes=$received_bytes
old_transmitted_bytes=$transmitted_bytes
old_time=$now

print_volume() {
	volume="$(amixer get Master | tail -n1 | sed -r 's/.*\[(.*)%\].*/\1/')"
	if test "$volume" -gt 0
	then
		echo -e "\uE05D${volume}"
	else
		echo -e "Mute"
	fi
}

get_battery_combined_percent() {

	# get charge of all batteries, combine them
	total_charge=$(expr $(acpi -b | awk '{print $4}' | grep -Eo "[0-9]+" | paste -sd+ | bc));

	# get amount of batteries in the device
	battery_number=$(acpi -b | wc -l);

	percent=$(expr $total_charge / $battery_number);

	echo $percent;
}

get_battery_charging_status() {

	if $(acpi -b | grep --quiet Discharging)
	then
		echo "🔋";
	else # acpi can give Unknown or Charging if charging, https://unix.stackexchange.com/questions/203741/lenovo-t440s-battery-status-unknown-but-charging
		echo "🔌";
	fi
}



print_bat(){
	#hash acpi || return 0
	#onl="$(grep "on-line" <(acpi -V))"
	#charge="$(awk '{ sum += $1 } END { print sum }' /sys/class/power_supply/BAT*/capacity)%"
	#if test -z "$onl"
	#then
		## suspend when we close the lid
		##systemctl --user stop inhibit-lid-sleep-on-battery.service
		#echo -e "${charge}"
	#else
		## On mains! no need to suspend
		##systemctl --user start inhibit-lid-sleep-on-battery.service
		#echo -e "${charge}"
	#fi
	#echo "$(get_battery_charging_status) $(get_battery_combined_percent)%, $(get_time_until_charged )";
	echo "$(get_battery_charging_status) $(get_battery_combined_percent)%";
}
get_bytes

# Calculates speeds
vel_recv=$(get_velocity $received_bytes $old_received_bytes $now)
vel_trans=$(get_velocity $transmitted_bytes $old_transmitted_bytes $now)

xsetroot -name "Hello lsp! $vel_recv $vel_trans $(print_volume) $(print_bat)"

# Update old values to perform new calculations
old_received_bytes=$received_bytes
old_transmitted_bytes=$transmitted_bytes
old_time=$now

exit 0
