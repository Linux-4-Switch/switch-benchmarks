#!/bin/bash

#cpu_freqs=( 102000 204000 306000 408000 510000 612000 714000 816000 918000 1020000 1122000 1224000 1326000 1428000 1581000 1683000 1785000 1887000 1989000 2091000 )
cpu_freqs=($(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_available_frequencies))
#gpu_freqs=( 76800000 153600000 230400000 307200000 384000000 460800000 537600000 614400000 691200000 768000000 844800000 921600000 )
gpu_freqs=($(cat /sys/devices/57000000.gpu/devfreq/57000000.gpu/available_frequencies))


cpu_bench_avg() {
	echo 1600000000 | sudo tee /sys/kernel/debug/clk/override.emc/clk_update_rate
	echo 1 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state
	cat <<< "0" > "/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq"

	for freq in "${cpu_freqs[@]}"; do
		echo $freq | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
		cat <<< "$freq" > "/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq"
		sysbench cpu --threads=4 run
		current=$(cat '/sys/devices/7000c000.i2c/i2c-0/0-0036/power_supply/max170xx_battery/current_avg')
		voltage=$(cat '/sys/devices/7000c000.i2c/i2c-0/0-0036/power_supply/max170xx_battery/voltage_avg')

		echo "$current * $voltage / 1000000000" | bc
	done

	echo 0 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state
}

cpu_power_avg() {
	echo 1600000000 | sudo tee /sys/kernel/debug/clk/override.emc/clk_update_rate
	echo 1 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state
	cat <<< "0" > "/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq"
	echo "0" | sudo tee "/sys/devices/pwm-fan/temp_control"
	echo "170" | sudo tee "/sys/devices/pwm-fan/target_pwm"

	for freq in "${cpu_freqs[@]}"; do
		echo $freq | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
		cat <<< "$freq" > "/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq"
		sleep 120
		current=$(cat '/sys/devices/7000c000.i2c/i2c-0/0-0036/power_supply/max170xx_battery/current_avg')
		voltage=$(cat '/sys/devices/7000c000.i2c/i2c-0/0-0036/power_supply/max170xx_battery/voltage_avg')
		echo "$current * $voltage / 1000000000" | bc
	done

	echo 0 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state
	echo "0" | sudo tee "/sys/devices/pwm-fan/target_pwm"
	echo "1" | sudo tee "/sys/devices/pwm-fan/temp_control"
}

gpu_bench_avg() {
	echo 1600000000 | sudo tee /sys/kernel/debug/clk/override.emc/clk_update_rate
	echo 1 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state

	echo 1581000 | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	echo 1581000 | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
	cat <<< "0" > "/sys/devices/57000000.gpu/devfreq/57000000.gpu/min_freq"

	for freq in "${gpu_freqs[@]}"; do
		cat <<< "$freq" > "/sys/devices/57000000.gpu/devfreq/57000000.gpu/max_freq"
		echo $freq | sudo tee /sys/devices/57000000.gpu/devfreq/57000000.gpu/min_freq
		vkmark -p immediate -b :duration=50 -b texture

		current=$(cat '/sys/devices/7000c000.i2c/i2c-0/0-0036/power_supply/max170xx_battery/current_avg')
		voltage=$(cat '/sys/devices/7000c000.i2c/i2c-0/0-0036/power_supply/max170xx_battery/voltage_avg')
		echo "$current * $voltage / 1000000000" | bc
	done

	echo 0 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state
}

gpu_power_avg() {
	echo 1600000000 | sudo tee /sys/kernel/debug/clk/override.emc/clk_update_rate
	echo 1 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state

	echo 1581000 | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	echo 1581000 | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
	cat <<< "0" > "/sys/devices/57000000.gpu/devfreq/57000000.gpu/min_freq"
	echo "0" | sudo tee "/sys/devices/pwm-fan/temp_control"
	echo "170" | sudo tee "/sys/devices/pwm-fan/target_pwm"

	for freq in "${gpu_freqs[@]}"; do
		cat <<< "$freq" > "/sys/devices/57000000.gpu/devfreq/57000000.gpu/max_freq"
		echo $freq | sudo tee /sys/devices/57000000.gpu/devfreq/57000000.gpu/min_freq

		sleep 120
		current=$(cat '/sys/devices/7000c000.i2c/i2c-0/0-0036/power_supply/max170xx_battery/current_avg')
		voltage=$(cat '/sys/devices/7000c000.i2c/i2c-0/0-0036/power_supply/max170xx_battery/voltage_avg')
		echo "$current * $voltage / 1000000000" | bc
	done

	echo 0 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state
	echo "0" | sudo tee "/sys/devices/pwm-fan/target_pwm"
	echo "1" | sudo tee "/sys/devices/pwm-fan/temp_control"
}

iops() {
	if [[ ! -e /dev/$disk ]]; then
		echo "Disk couldn't be found in /dev."
		exit 1
	fi

	iostat -d "$disk" | grep "$disk" | awk '{ print $2; }'
}

usage() { echo "Usage: $0 [--cbench] [--cpower] [--gbench] [--gpower] [--iops <disk>]" 1>&2; exit 1; }

parse_opt=`getopt --long 'cbench,cpower,gbench,gpower,iops:' \
	--name "$(basename "$0")" \
	--options "" \
	-- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$parse_opt"

while true; do
	case "$1" in
        	--cbench)
			cpu_bench_avg; shift ;;
		--cpower)
			cpu_power_avg; shift ;;
		--gbench)
			gpu_bench_avg; shift ;;
		--gpower)
			gpu_power_avg; shift ;;
		--iops)
			shift; disk="$1"; iops; shift ;;
		--)
			shift; break ;;
		*)
			usage ;;
	esac
done
