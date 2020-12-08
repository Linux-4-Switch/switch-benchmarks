#!/bin/bash
timer=0
sleep 2
while [ $timer -lt 120 ]; do
    current_avg=$(</sys/class/power_supply/max170xx_battery/current_avg)
    voltage_avg=$(</sys/class/power_supply/max170xx_battery/voltage_avg)
    current_now=$(</sys/class/power_supply/max170xx_battery/current_now)
    voltage_now=$(</sys/class/power_supply/max170xx_battery/voltage_now)
    voltage_ocv=$(</sys/class/power_supply/max170xx_battery/voltage_ocv)
    charging=$(</sys/class/power_supply/max170xx_battery/status)
    battery_temp=$(</sys/class/power_supply/max170xx_battery/temp)

    echo $voltage_avg,$voltage_now,$voltage_ocv,$current_avg,$current_now,$charging,$battery_temp
    sleep 2
    timer=$(($timer + 2))
done
