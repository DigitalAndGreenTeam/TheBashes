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
    dos2unix $tmpHostsFile      ### checker s'il est installé auparavant
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
    disk=$(df -h | awk '{print $5" "$4}' | grep /)
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

fct_commons() {
    machine_name_fqdn=$(hostname -f | head -n 1)
    release=$(cat /etc/redhat-release | awk -F"release " {'print $2'} | awk -F" " {'print $1'})
    CPU=$(cat /proc/cpuinfo | grep processor | tail -n 1 | awk -F": " {'print $2'})
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
    distributor=$(cat /etc/redhat-release | awk -F"release" {'print $1'})
}

### Main ###################################################################

fct_commons
fct_server
echo ' "machine_name_fqdn": "'$machine_name_fqdn'", ' >>$file_name
echo ' "distributor": "'$distributor'", ' >>$file_name
echo ' "release": "'$release'", ' >>$file_name
echo ' "CPU": "'$CPU'", ' >>$file_name
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
