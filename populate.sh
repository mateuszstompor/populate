#!/bin/bash

DESTINATION_DIRECTORY=/tmp/

function banner {
	echo "********** $1 **********"
}

function fail {
	if [[ ! $# -eq 0 ]]
	then
		echo $1
	fi
	banner "FAILURE"
	exit 1
}

function load_env {
	local directory=$(dirname "$0")
  local file="${directory}/.env.$1"
  if [ -f $file ]
	then
    set -a
    source $file
    set +a
  else
    echo "No $file file found" 1>&2
    exit 1
  fi
}

function waits {
	local arguments=("$@")
	STATUS=()
	for (( i=0; i<$#; i++ )); do
	  wait ${arguments[${i}]}
	  STATUS[$i]=$?
	done
}


load_env populate

if [[ -z NAMES ]] || [[ -z USER ]]
then
	fail "Mandatory env variables are not set"
fi

if [[ $# != 1 ]]
then
	fail "You must provide exactly one argument"
fi

if [[ ! -f $1 ]]
then
	fail "Provided file does not exists"
fi

if [[ ! $1 == *.rpm ]]
then
	fail "Only .rpm files are suppored"
fi

ALL_HOSTS=($NAMES)

banner "Copying the package"
PIDS=()
for HOST in $NAMES
do
	scp $1 ${USER}@${HOST}:${DESTINATION_DIRECTORY} > /dev/null 2>&1 &
	PIDS+=($!)
done

waits ${PIDS[@]}

INSTALL_ELIGIBLE_HOSTS=()
INSTALL_SKIPPED_HOSTS=()
for (( i = 0; i < ${#STATUS[@]}; i++ ))
do
	printf "${ALL_HOSTS[${i}]}..."
	if [[ ${STATUS[${i}]} -eq 0 ]]
	then
		echo "OK"
		INSTALL_ELIGIBLE_HOSTS+=(${ALL_HOSTS[${i}]})
	else
		echo "FAILED"
		INSTALL_SKIPPED_HOSTS+=(${ALL_HOSTS[${i}]})
	fi
done

banner "Installing the pacakge"
PIDS=()
for HOST in ${INSTALL_ELIGIBLE_HOSTS[@]}
do
	ssh ${USER}@$HOST rpm -U ${DESTINATION_DIRECTORY}$1 --force > /dev/null 2>&1 &
	PIDS+=($!)
done

waits ${PIDS[@]}

for (( i = 0; i < ${#STATUS[@]}; i++ ))
do
	printf "${INSTALL_ELIGIBLE_HOSTS[${i}]}..."
	[[ ${STATUS[${i}]} -eq 0 ]] && echo "OK" || echo "FAILED"
done

for (( i = 0; i < ${#INSTALL_SKIPPED_HOSTS[@]}; i++ ))
do
	echo "${INSTALL_SKIPPED_HOSTS[${i}]}...FAILED"
done
banner "FINISHED"
