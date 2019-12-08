#! /usr/bin/env bash
##
## Script to list some informations from a machine
## Basic informations
##
## November 2019
##
## Olivier Leteneur

## Il est nécessaire de faire des vérifs de versions des différentes requêtes pour être certains que ça puisse fonctionner
## ou alors on met en place des seuils à minima
## Recours à un menu ?

## informations agents (puppet, nagios etc.) ?

### BEGIN OF SCRIPT ###
Recolt_version=0.0.1

### Declare Variable Name of Log ###################################################################
source Recolt.cfg

machine_name_fqdn=$(hostname | head -n 1)

time=$(date +%Y%m%d)
file_time=$(date +%Y-%m-%d' %H:%M:%S')
file_name="$LOG_DIR$machine_name_fqdn.$time"
jsonFile="$file_name.json"

# rm -f $jsonFile  ### Ne peut pas fonctionner en toute logique
# rm -f $file_name ### Ne peut pas fonctionner en toute logique

### Open the brackets for the Json file ###################################################################
echo "{" >>$file_name

### Declare Functions ###################################################################

get_hosts() {
    tmpHostsFile="/tmp/tmpHostsFile"
    cat /etc/hosts | sed '/^$/d' | sed '/#/d' | sed '/::/d' >$tmpHostsFile
#    dos2unix $tmpHostsFile      ### checker s'il est installé auparavant
    echo '"hosts": [' >>$file_name
    while read line; do
        found_ip=$(echo $line | awk '{print $1}')
        nvalue=$(echo $line | awk '{print $2" "$3" "$4" "$5" "$6}')
        echo ' {"ip": "'$found_ip'","fqdn": "'$nvalue'"},' >>$file_name
    done <"$tmpHostsFile"
    echo ' {"ip": "","fqdn": ""}' >>$file_name
    echo "]," >>$file_name
}

check_disk() {
    echo '"check_disk": {' >>$file_name
    disk=$(df -h | awk '{print $6" "$5}' | grep /)
    echo "${disk//%/}" | while read line; do
        fs=$(echo $line | awk '{print $1}')
        size=$(echo $line | awk '{print $2}')
        if [ $size -lt 70 ]; then
            echo ' "'$fs'": { "value": "'$size'", "message": "INFO" },' >>$file_name
        else
            if [ $size -lt 95 ] && [ $size -gt 69 ]; then
                echo ' "'$fs'": { "value": "'$size'", "message": "WARNING" },' >>$file_name
            else
                if [ $size -gt 94 ]; then
                    echo ' "'$fs'": { "value": "'$size'", "message": "ALERTE" },' >>$file_name
                fi
            fi
        fi
    done
    echo "}," >>$file_name
}
fct_network() {

    echo '"check_reseaux": {' >>$file_name



    inter=$(cat /proc/net/dev | awk '{ print $1 }'  | grep -v Inter | grep -v face | grep -v lo )
    echo "${inter//:/}" | while read line; do
        nom_inter=$(echo $line)
        debit=$(ip -4 addr | grep $line | grep -v inet | awk '{ print $13}')
        ip_addr=$(ip -4 addr | grep $line | grep inet | awk '{print $2}')
        echo "${ip_addr}" | while read addr; do
        echo ' "'$nom_inter'": { "ip": "'$addr'", "debit": "'$debit'" },' >>$file_name
      done
    done
    echo "}," >>$file_name
}

fct_packages() {

    echo '"check_packages": {' >>$file_name



    packages=$(dpkg-query -f '${binary:Package},${Version}\n' -W)
    echo "${packages}" | while read line; do
        nom_packages=$(echo $line | awk -F "," '{ print $1 }')
        version_packages=$(echo $line | awk -F "," '{ print $2 }')
          echo ' "'$nom_packages'": { "version_package": "'$version_packages'" },' >>$file_name
    done
    echo "}," >>$file_name
}
fct_cpu_usage () {

    echo '"check_cpu_usage": {' >>$file_name

    top -b -n 3 | grep Cpu > $_LOG_DIR/Cpu_tmp
    cat $_LOG_DIR/Cpu_tmp | while read -r line; do
        cpu_usage_user=$(echo $line | awk '{ print $2 }'| awk -F "," '{ print $1 }')
        cpu_usage_system=$(echo $line | awk '{ print $4 }'| awk -F "," '{ print $1 }')
        cpu_usage_nice=$(echo $line | awk '{ print $6 }'| awk -F "," '{ print $1 }')
        cpu_usage_idle=$(echo $line | awk '{ print $8 }'| awk -F "," '{ print $1 }')
        cpu_usage_wait=$(echo $line | awk '{ print $10 }'| awk -F "," '{ print $1 }')
        cpu_usage_tshi=$(echo $line | awk '{ print $12 }'| awk -F "," '{ print $1 }')
        cpu_usage_tssi=$(echo $line | awk '{ print $14 }'| awk -F "," '{ print $1 }')
        cpu_usage_tsth=$(echo $line | awk '{ print $16 }'| awk -F "," '{ print $1 }')

        if [ $cpu_usage_idle -lt 20 ]; then
            echo ' "Cpu": { "cpu_usage_user": "'$cpu_usage_user'", "cpu_usage_system": "'$cpu_usage_system'", "cpu_usage_nice": "'$cpu_usage_nice'", "cpu_usage_idle": "'$cpu_usage_idle'", "cpu_usage_wait": "'$cpu_usage_wait'", "cpu_usage_tshi": "'$cpu_usage_tshi'", "cpu_usage_tssi": "'$cpu_usage_tssi'", "cpu_usage_tsth": "'$cpu_usage_tsth'", "message": "ALERT"  },' >>$file_name
        else

        echo ' "Cpu": { "cpu_usage_user": "'$cpu_usage_user'", "cpu_usage_system": "'$cpu_usage_system'", "cpu_usage_nice": "'$cpu_usage_nice'", "cpu_usage_idle": "'$cpu_usage_idle'", "cpu_usage_wait": "'$cpu_usage_wait'", "cpu_usage_tshi": "'$cpu_usage_tshi'", "cpu_usage_tssi": "'$cpu_usage_tssi'", "cpu_usage_tsth": "'$cpu_usage_tsth'", "message": "INFO"  },' >>$file_name
      fi
    done
    echo "}," >>$file_name
}

fct_commons() {
    machine_name_fqdn=$(hostname -f | head -n 1)
    release=$(cat /etc/debian_version)
    CPU=$(cat /proc/cpuinfo | grep processor | tail -n 1 | awk -F": " {'print $2'})
    CPU_model=$(cat /proc/cpuinfo | grep "model name" | tail -n 1 | awk -F": " {'print $2'} )
    let "CPU += 1"
    TotalMemory=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    check_disk
##    IPAddr=$(ifconfig | grep -i "inet addr" | grep -v 127.0.0.1 | awk -F"addr:" {'print $2'} | awk -F"  Bcast" {'print $1'})
    get_hosts
    start=$(who -b | awk '{print $3,$4}')
    last_start=$(uptime | awk -F"," '{print $1}')
}

### Machine
fct_server() {
    version=$(cat /etc/debian_version)
    distributor=debian_$version
    kernel_version=$(uname -a | awk -F" " '{print $3}')
}

### Main ###################################################################

fct_commons
fct_server
fct_network
fct_cpu_usage
fct_packages
echo ' "machine_name_fqdn": "'$machine_name_fqdn'", ' >>$file_name
echo ' "distributor": "'$distributor'", ' >>$file_name
echo ' "kernel_version": "'$kernel_version'", ' >>$file_name
echo ' "release": "'$release'", ' >>$file_name
echo ' "CPU": "'$CPU'", ' >>$file_name
echo ' "CPU_model": "'$CPU_model'", ' >>$file_name
echo ' "TotalMemory": "'$TotalMemory'", ' >>$file_name
## echo ' "IPAddr": "'$IPAddr'", ' >>$file_name
echo ' "start": "'$start'", ' >>$file_name
echo ' "last_start": "'$last_start'", ' >>$file_name

echo ' "file_creation": "'$file_time'", ' >>$file_name
echo ' "Recolt_version": "'$Recolt_version'" ' >>$file_name

### Close the brackets for the Json file ###################################################################

echo "}" >>$file_name
sed -r ':a;N;$!ba;s/,\n}/\n}/gm' $file_name >$jsonFile
sed -r 's/\=/"\: "/g' $jsonFile >$file_name
cat $file_name >$jsonFile
# rm -f $file_name

sleep 2s

### End of Main ###################################################################

### END OF SCRIPT ###

#################################################################################
#################################################################################
