#!/bin/bash

cpu_freqs=($(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_available_frequencies))
gpu_freqs=($(cat /sys/devices/57000000.gpu/devfreq/57000000.gpu/available_frequencies))
bench=('vulkan_single' 'vulkan_multi' 'opengl_single' 'opengl_multi')
btype=('vk' 'vk' 'gl' 'gl')
type=('' '-m' '' '-m')
#vulkan_single=(1 2 3 4)
#vulkan_multi=(1 2 3)
#opengl_single=(1 2 3 4)
#opengl_multi=(1)
vulkan_single=()
vulkan_multi=(1 3)
opengl_single=()
opengl_multi=()
cd ~/GL_vs_VK/bin

echo 1600000000 | sudo tee /sys/kernel/debug/clk/override.emc/clk_update_rate >/dev/null
echo 1 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state /dev/null

echo ${cpu_freqs[-1]} | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq >/dev/null
echo ${cpu_freqs[-1]} | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq >/dev/null
echo ${gpu_freqs[0]} | sudo tee /sys/devices/57000000.gpu/devfreq/57000000.gpu/min_freq >/dev/null
echo "0" | sudo tee "/sys/devices/pwm-fan/temp_control"
echo "255" | sudo tee "/sys/devices/pwm-fan/target_pwm"

num=0
for t in ${bench[@]}; do
	echo ""
	echo ${bench[num]}
	for t2 in $(eval echo \${$t[@]}); do
		echo ""
		echo "Benchmark #"
		echo $t2
		echo ""
		for freq in "${gpu_freqs[@]}"; do
			echo $freq | sudo tee /sys/devices/57000000.gpu/devfreq/57000000.gpu/max_freq
			echo $freq | sudo tee /sys/devices/57000000.gpu/devfreq/57000000.gpu/min_freq >/dev/null

			~/GL_vs_VK/bin/GL_vs_VK -t $t2 -api ${btype[num]} ${type[num]} -benchmark 2>/dev/null | sed -n 's/.Average FPS//p'
			echo ${gpu_freqs[0]} | sudo tee /sys/devices/57000000.gpu/devfreq/57000000.gpu/min_freq >/dev/null
			echo ${gpu_freqs[-1]} | sudo tee /sys/devices/57000000.gpu/devfreq/57000000.gpu/max_freq >/dev/null
		done

	done
	num=$num+1
done

echo 0 | sudo tee /sys/kernel/debug/clk/override.emc/clk_state
echo "0" | sudo tee "/sys/devices/pwm-fan/target_pwm"
echo "1" | sudo tee "/sys/devices/pwm-fan/temp_control"
