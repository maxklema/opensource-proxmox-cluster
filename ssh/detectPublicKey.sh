#!/bin/bash
# Detect if the user in the current session logged in via an SSH public key
# Last Updated June 17th 2025 Maxwell Klema

USER=$(whoami)
PUBLIC_KEY_LIST="../.ssh/authorized_keys"
TEMP_PUB_FILE="temp_pubs/key.pub"

# Extract latest public key fingerprint based on login from USER

LAST_LOGIN=$(journalctl _COMM=sshd | grep "Accepted publickey for $USER" | tail -1 )
KEY_FINGERPRINT=$(echo $LAST_LOGIN | grep -o 'SHA256[^ ]*')

# Iterate over each public key, compute fingerprint, see if there is a match

while read line; do
	echo "$line" > "$TEMP_PUB_FILE"
	PUB_FINGERPRINT=$(ssh-keygen -lf "$TEMP_PUB_FILE" | awk '{print $2}')
	if [[ "$PUB_FINGERPRINT" == "$KEY_FINGERPRINT" ]]; then
		echo "Public key found for $USER - Located in $TEMP_PUB_FILE"
		exit 0
	fi
done < <(tac $PUBLIC_KEY_LIST) #Iterates backwards without creating subprocess (allows exit in loop)

echo "" > "$TEMP_PUB_FILE"




