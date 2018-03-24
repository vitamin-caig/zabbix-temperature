#!/bin/bash
version=0.2

if [[ -e /etc/zabbix/temperature.conf ]]; then
   . /etc/zabbix/temperature.conf
fi

case "$1" in
"--temperature-discovery")
    # Get the list of temperature devices
    echo -en '{\n  "data":\n  ['
    for SensorInput in $(/usr/bin/find /sys/devices -type f -name 'temp*_input' | sort)
    do
        SensorLabelFile=${SensorInput/_input/_label}
        if [ -e "${SensorLabelFile}" ]; then
          SensorLabel=$(cat ${SensorLabelFile})
        else
          SensorLabel=$(cat $(dirname ${SensorInput})/name)
          SensorSuffix=$(basename ${SensorInput})
          SensorSuffix=${SensorSuffix:4:1}
        fi
        if [[ $IgnoreSensors ]]; then
            # Check ignore list by sensor name first
            if grep -qE '('${IgnoreSensors}')' $SensorLabel; then
                continue
            fi
            # Check ignore list by path to sensor as well
            if (echo $SensorInput | grep -qE '('${IgnoreSensors}')'); then
                continue
            fi
        fi
        echo -en "$Delimiter\n    "
        echo -en "{\"{#SENSORLABEL}\":\"${SensorLabel}${SensorSuffix+:${SensorSuffix}}\",\"{#SENSORINPUT}\":\"${SensorInput}\""
        SensorMax=${SensorInput/_input/_max}
        if [[ -e "$SensorMax" ]]; then
            echo -en ",\"{#SENSORMAX}\":\"${SensorMax}\""
        fi
        echo -en "}"
        Delimiter=","
    done
    echo -e '\n  ]\n}'
    exit 0
;;
"--fan-discovery")
    # Get the list of fan devices
    typeset -i cntLines=0
    echo -en '{\n  "data":\n  ['
    for FanInput in $(/usr/bin/find /sys/devices -type f -name fan*_input | sort)
    do
        cntLines=${cntLines}+1
        FanLabelFile=${FanInput/_input/_label}
        if [ -e "${FanLabelFile}" ]; then
          FanLabel=$(cat ${FanLabelFile})
        else
          FanLabelFile=$(dirname ${FanInput})/name
          if [ -e "${FanLabelFile}" ]; then
            FanLabel=$(cat ${FanLabelFile})
          else
            FanLabel="Fan ${cntlines}"
          fi
        fi
        echo -en "$Delimiter\n    "
        echo -en "{\"{#FANLABEL}\":\"${FanLabel}\",\"{#FANINPUT}\":\"${FanInput}\"}"
        Delimiter=","
    done
    echo -e '\n  ]\n}'
    exit 0
;;
*)
    # This should not occur!
    echo "ERROR on `hostname` in $0"
    exit 1
;;
esac
