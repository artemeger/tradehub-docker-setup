#!/bin/bash

while getopts "w:" opt
do
   case "$opt" in
      w ) wallet="$OPTARG" ;;
   esac
done

printf "$wallet\n$wallet\n$wallet\n" | switcheocli keys import --keyring-backend file val_key /root/.key/val_key

export DAEMON_NAME=switcheod
export DAEMON_HOME=${HOME}/.switcheod
export PATH=${HOME}/.switcheod/cosmovisor/current/bin:${HOME}/.switcheod/cosmovisor/genesis/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

WALLET_PASSWORD=$wallet cosmovisor start-all