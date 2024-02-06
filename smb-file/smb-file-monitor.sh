#!/bin/bash

# Name : smb-file-monitor.sh
# Author : fadly.tabrani@gmail.com | fads@f5.com
# Version: 1.0

# Mandatory variables.
# USERNAME - username of user account.
# SHARE - directory shared on server. 
# FILE - name of file being checked.

# Optional variables.
# DOMAIN - domain of user account.
# MAX_PROTOCOL - SMB1/SMB2/SMB3, defaults to SMB3.
# DIRECTORY - directory where file resides.

# Remove IPv6/IPv4 compatibility prefix (LTM passes addresses in IPv6 format)
IP=`echo $1 | sed 's/::ffff://'`

# Save the port for use in the shell command
PORT=$2

# Check if there is a prior instance of the monitor running
pidfile="/var/run/`basename $0`.$IP.$PORT.pid"
if [ -f $pidfile ]; then
    kill -9 `cat $pidfile` > /dev/null 2>&1
    echo "EAV `basename $0`: exceeded monitor interval, needed to kill ${IP}:${PORT} with PID `cat $pidfile`"
fi

# Add the current PID to the pidfile
echo "$$" > $pidfile

STATUS=0

# --- Check variables, set default values and adjust for smbclient command.
[[ -z $USERNAME ]] && STATUS=1
[[ -z $PASSWORD ]] && STATUS=1
[[ -z $MAX_PROTOCOL ]] && MAX_PROTOCOL=SMB3
[[ -z $SHARE ]] && STATUS=1
[[ -z $FILE ]] && STATUS=1

if [[ -n "$DOMAIN" ]]; then
    USERNAME="$DOMAIN\\$USERNAME"
fi

if [[ -n "$DIRECTORY" ]]; then
    FILE_PATH="$DIRECTORY\\$FILE"
else
    FILE_PATH=$FILE
fi
# ---

# Run command if all variables are in place.
if [ $STATUS -eq 0 ]; then
    cd /tmp
    smbclient --user $USERNAME%$PASSWORD --max-protocol $MAX_PROTOCOL --port $PORT //$IP/$SHARE --command "du $FILE_PATH" > /dev/null 2>&1
    STATUS=$?
fi

# Check command ran sucessfully and return.
if [ $STATUS -eq 0 ]; then
    rm -f $pidfile
    echo "UP"
else
    rm -f $pidfile
fi
