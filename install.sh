#!/bin/bash

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

function success {
	banner "SUCCESS"
}

printf "Enter hostnames of nodes in the cluster. \nProvide them as space separated words in a single line\n"
read HOSTNAMES < /dev/stdin
PINGABLE=()
for NAME in $HOSTNAMES; do
  ping -c 2 $NAME > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo "$NAME is pingable"
    PINGABLE+=($NAME)
  else
    echo "$NAME is not pingable, won't be added to the list of nodes"
  fi
done

if [[ ${#PINGABLE[@]} -eq 0 ]]
then
	fail "There are no pingable hosts"
else
	echo "Pingable hosts ${PINGABLE[@]}"
fi

echo "Provide user to log over ssh"
read USER < /dev/stdin

echo "Checking ssh conectivity..."
SSHABLE=()
for NAME in ${PINGABLE[@]}; do
  ssh -o ConnectTimeout=1 -o ConnectionAttempts=1 -q $USER@$NAME exit > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    SSHABLE+=($NAME)
    echo "$NAME can be accessed"
  else
    echo "$NAME cannnot be accessed, won't be added to the list of nodes"
  fi
done

if [[ ${#SSHABLE[@]} -eq 0 ]]
then
	fail "There are no sshable hosts"
fi

echo "SSHABLE hosts ${SSHABLE[@]}"
echo "Populating the script"
FILENAME=populate.sh
ENV_FILENAME=.env.populate
echo "NAMES=\"${SSHABLE[@]}\"" > ${ENV_FILENAME}
echo "USER=${USER}" >> ${ENV_FILENAME}
for HOST in ${SSHABLE[@]}; do
	scp ${FILENAME} ${USER}@$HOST:/usr/local/bin/populate > /dev/null 2>&1
	scp ${ENV_FILENAME} ${USER}@$HOST:/usr/local/bin/ > /dev/null 2>&1
done
rm -f ${ENV_FILENAME}

success
