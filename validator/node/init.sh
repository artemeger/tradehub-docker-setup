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
export DAEMON_ALLOW_DOWNLOAD_BINARIES=true
export PATH=${HOME}/.switcheod/cosmovisor/current/bin:${HOME}/.switcheod/cosmovisor/genesis/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

# Start validator
WALLET_PASSWORD=$wallet bash -c "exec -a validator_process cosmovisor start-all &"
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start validator_process: $status"
  exit $status
fi

old_height=0
counter=0

while sleep 5; do

  echo "Checking validator process..."
  ps aux |grep validator_process |grep -q -v grep
  PROCESS_1_STATUS=$?
  if [ $PROCESS_1_STATUS -ne 0 ]; then
    echo "Validator process exited. Abort"
    exit 1
  fi

  echo "Checking stalling..."
  local_height=$(curl -s "http://localhost:26657/status" | jq -r '.result.sync_info.latest_block_height')
  if [ $local_height -ne $old_height ]; then
		echo "Blockheight increasing - OK: $(($local_height-$old_height)) Counter: $counter"
		counter=$((0))
		old_height=$((local_height))
	else
		counter=$((counter+1))
		echo "Blockheight stalled - BAD: $(($local_height-$old_height)) Counter: $counter"
	fi
	if [ $counter -gt 20 ]; then
	  echo "Node seems stalled. Abort"
		exit 1
	fi

done