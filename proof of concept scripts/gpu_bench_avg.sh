#!/bin/bash
echo 1600000000 | sudo tee /sys/kernel/debug/clk/override.emc/clk_update_rate
echo 1 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state

echo 1581000 | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 1581000 | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
cat <<< "0" > "/sys/devices/57000000.gpu/devfreq/57000000.gpu/min_freq"
clear
list=( 76800000 153600000 230400000 307200000 384000000 460800000 537600000 614400000 691200000 768000000 844800000 921600000 )
##output=2091000
for output in "${list[@]}"
##while true
do
cat <<< "$output" > "/sys/devices/57000000.gpu/devfreq/57000000.gpu/max_freq"
echo $output | sudo tee /sys/devices/57000000.gpu/devfreq/57000000.gpu/min_freq
vkmark -p immediate -b :duration=50 -b texture

current=$(cat '/sys/devices/7000c000.i2c/i2c-0/0-0036/power_supply/max170xx_battery/current_avg')
voltage=$(cat '/sys/devices/7000c000.i2c/i2c-0/0-0036/power_supply/max170xx_battery/voltage_avg')
##echo $current
##echo $voltage
echo "$current * $voltage / 1000000000" | bc


done
echo 0 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state
