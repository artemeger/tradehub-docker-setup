#!/bin/bash

while getopts "w:" opt
do
   case "$opt" in
      w ) wallet="$OPTARG" ;;
   esac
done

printf "$wallet\n$wallet\n$wallet\n" | switcheocli keys import --keyring-backend file val_key /root/.key/val_key

WALLET_PASSWORD=$wallet switcheod start-all -a