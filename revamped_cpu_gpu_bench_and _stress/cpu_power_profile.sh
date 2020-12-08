#!/bin/bash

cpu_freqs=(102000 204000 306000 408000 510000 612000 714000 816000 918000 1020000 1122000 1224000 1326000 1428000 1581000 1683000 1785000 1887000 1989000 2091000)
gpu_freqs=(76800000 153600000 230400000 307200000 384000000 460800000 537600000 614400000 691200000 768000000 844800000 921600000)

echo 1600000000 | sudo tee /sys/kernel/debug/clk/override.emc/clk_update_rate
echo 1 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state
cat <<<"0" >"/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq"
echo "0" | sudo tee "/sys/devices/pwm-fan/temp_control"
echo "255" | sudo tee "/sys/devices/pwm-fan/target_pwm"

for freq in "${cpu_freqs[@]}"; do
	echo $freq | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
	cat <<<"$freq" >"/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq"
	./stats.sh &
	sudo ionice -c 2 -n 0 nice -n 1 stress-ng --matrix 0 --matrix-size 64 -t 130 --metrics-brief
done

echo 0 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state
echo "0" | sudo tee "/sys/devices/pwm-fan/target_pwm"
echo "1" | sudo tee "/sys/devices/pwm-fan/temp_control"
