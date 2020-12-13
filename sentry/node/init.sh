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

# Start oracle
WALLET_PASSWORD=$wallet bash -c "exec -a oracle_process switcheod start --oracle --exclude=\"db,cosmos-rest\" --exclude-node &"
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start oracle_process: $status"
  exit $status
fi

# Start persistence
WALLET_PASSWORD=$wallet bash -c "exec -a persistence_process switcheod start --db --exclude-node &"
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start persistence_process: $status"
  exit $status
fi

# Start cosmovisor
WALLET_PASSWORD=$wallet bash -c "exec -a cosmovisor_process cosmovisor start -a --exclude=\"oracle,db\" &"
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start cosmovisor_process: $status"
  exit $status
fi

while sleep 5; do
  echo "Checking Processes..."
  ps aux |grep oracle_process |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep persistence_process |grep -q -v grep
  PROCESS_2_STATUS=$?
  ps aux |grep cosmovisor_process |grep -q -v grep
  PROCESS_3_STATUS=$?
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 -o $PROCESS_3_STATUS -ne 0 ]; then
    echo "One of the processes exited. Abort"
    exit 1
  fi
done