#!/bin/bash

#cpu_freqs=( 102000 204000 306000 408000 510000 612000 714000 816000 918000 1020000 1122000 1224000 1326000 1428000 1581000 1683000 1785000 1887000 1989000 2091000 )
cpu_freqs=($(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_available_frequencies))
#gpu_freqs=(76800000 153600000 230400000 307200000 384000000 460800000 537600000 614400000 691200000 768000000 844800000 921600000)
gpu_freqs=($(cat /sys/devices/57000000.gpu/devfreq/57000000.gpu/available_frequencies))

echo 1600000000 | sudo tee /sys/kernel/debug/clk/override.emc/clk_update_rate >/dev/null
echo 1 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state >/dev/null
echo "0" | sudo tee "/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq" >/dev/null
echo "0" | sudo tee "/sys/devices/pwm-fan/temp_control" >/dev/null
echo "255" | sudo tee "/sys/devices/pwm-fan/target_pwm" >/dev/null

for freq in "${cpu_freqs[@]}"; do
	echo $freq | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
	echo $freq | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq >/dev/null
	sleep 2
	sudo ionice -c 2 -n 0 nice -n -10 sysbench cpu --threads=4 --max-time=10 run | sed -n 's/.*second://p'
	sleep 2
done
echo "1" | sudo tee "/sys/devices/pwm-fan/temp_control"
echo "100" | sudo tee "/sys/devices/pwm-fan/target_pwm"
echo "0" | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
echo "1020000" | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
