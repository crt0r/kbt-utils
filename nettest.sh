#!/usr/bin/env bash

CHECK_DOCKER=$1
LOG_PATH="/var/log/nettest.log"
SCRIPTS_DIR_PATH="/root/scripts"
SCRIPT_CURR_PATH="$PWD/nettest.sh"
AUTOSTART_STR="@reboot root $SCRIPTS_DIR_PATH/nettest.sh $CHECK_DOCKER"
IS_AUTOSTART=$(grep -P "nettest" "/etc/crontab")

ADDRESSES=("3.3.3.1" "3.3.3.10" "4.4.4.1" "4.4.4.100" "5.5.5.1" "5.5.5.100" "192.168.100.100" "192.168.100.200" "192.168.100.254" "172.16.100.100" "172.16.100.254")
HOSTS=("web-l.int.demo.wsr" "dns.int.demo.wsr" "www.demo.wsr" "internet.demo.wsr")

function copy_self() {
	mkdir -p $SCRIPTS_DIR_PATH
	cp $SCRIPT_CURR_PATH "$SCRIPTS_DIR_PATH/"
}

function unset_autostart() {
	sed -i "/nettest/d" /etc/crontab
}

function log() {
	echo $1
	printf "$(printf "*%.0s" {1..80})\n" >> $LOG_PATH
	printf "$1 ::\n\n" >> $LOG_PATH
	$1 | grep -Pv "^#" >> $LOG_PATH
}

function filter_command() {
	$1 | grep $2
}

function filter_df() {
	filter_command "df -h" "^//"
}

function filter_lsblk() {
	filter_command "lsblk" "raid"
}

if [ "$IS_AUTOSTART" == "" ]; then
	echo $AUTOSTART_STR >> /etc/crontab
	copy_self
	reboot
fi

echo "" > $LOG_PATH

log "hostname"
log "ip a"

for ADDR in ${ADDRESSES[@]}; do
	log "ping -c 4 $ADDR"
done

log "ip xfrm state"
log "iptables -t nat -L"

if [ "$CHECK_DOCKER" == "--check-docker" ]; then
	log "docker ps -a"
	log "docker images"
	log "docker volume ls"
fi

log "cat /etc/resolv.conf"

for HOST in ${HOSTS[@]}; do
	log "host $HOST"
done

log "timedatectl"
log "filter_df"
log "filter_lsblk"
log "cat /etc/fstab"
log "cat /etc/crontab"

unset_autostart
wall "DONE"
