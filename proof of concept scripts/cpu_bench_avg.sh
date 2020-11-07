#!/bin/bash
echo 1600000000 | sudo tee /sys/kernel/debug/clk/override.emc/clk_update_rate
echo 1 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state
cat <<< "0" > "/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq"
clear
list=( 102000 204000 306000 408000 510000 612000 714000 816000 918000 1020000 1122000 1224000 1326000 1428000 1581000 1683000 1785000 1887000 1989000 2091000 )
##output=2091000
for output in "${list[@]}"
##while true
do
echo $output | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
cat <<< "$output" > "/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq"
sysbench cpu --threads=4 run
current=$(cat '/sys/devices/7000c000.i2c/i2c-0/0-0036/power_supply/max170xx_battery/current_avg')
voltage=$(cat '/sys/devices/7000c000.i2c/i2c-0/0-0036/power_supply/max170xx_battery/voltage_avg')

##echo $current
##echo $voltage
echo "$current * $voltage / 1000000000" | bc


done
echo 0 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state
