#!/bin/bash

GETNEXTID=$(pvesh get /cluster/nextid) #Get the next available LXC ID
NEXTID=$GETNEXTID

# Get Container Type (PR/Beta/Stable)

read -p "Enter Container Type (PR/BETA/STABLE) →  " CONTAINER_TYPE

while [[ "$CONTAINER_TYPE" != "PR" && "$CONTAINER_TYPE" != "BETA" && "$CONTAINER_TYPE" != "STABLE" ]];
do
	echo "Invalid Container Type. Must be \"PR\", \"BETA\", or \"STABLE\"."
	read -p "Enter Container Type (PR/BETA/STABLE) →  " CONTAINER_TYPE
done

# Gather Container Details

read -p "Enter Application Name (One-Word) →  " CONTAINER_NAME

HOST_NAME_EXISTS=$(node hostnameRunner.js checkHostnameExists "$CONTAINER_NAME")

while [ $HOST_NAME_EXISTS == 'true' ]; do
	echo "Sorry! That name has already been registered. Try another name"
	read -p "Enter Application Name (One-Word) →  " CONTAINER_NAME
	HOST_NAME_EXISTS=$(node hostnameRunner.js checkHostnameExists "$CONTAINER_NAME")
done


read -sp "Enter Container Password →  " CONTAINER_PASSWORD
echo
read -sp "Confirm Container Password →  " CONFIRM_PASSWORD
echo

while [ "$CONFIRM_PASSWORD" != "$CONTAINER_PASSWORD" ]; do
	echo "Passwords did not match. Try again."
	read -sp "Enter Container Password →  " CONTAINER_PASSWORD
	echo
	read -sp "Confirm Container Password →  " CONFIRM_PASSWORD
	echo
done

# Attempt to detect public keys

echo -e "\n🔑 Attempting to Detect SSH Public Key for $(whoami)..."

DETECT_PUBLIC_KEY=$(./detectPublicKey.sh)

if [ "$DETECT_PUBLIC_KEY" == "Public key found for $(whoami)" ]; then
	PUBLIC_KEY_FILE="temp_pubs/key.pub"
	echo "🔐 Public Key Found!"
else
	echo "❌ Could not detect Public Key"
	read -p "Enter Path Public Key (Allows Easy Access to Container) [OPTIONAL] →  " PUBLIC_KEY_FILE

	# Check if file or directory exists

	while [[ "$PUBLIC_KEY_FILE" == *.pub && ! -e "$PUBLIC_KEY_FILE" ]]; do
		echo "❌ \"$PUBLIC_KEY_FILE\" does not exist. Enter either a valid .pub file or leave blank."
		read -p "Enter Path Public Key (Allows Easy Access to Container) [OPTIONAL] →  " PUBLIC_KEY_FILE
	done

	if [ "$PUBLIC_KEY_FILE" != *.pub ]; then
		PUBLIC_KEY_FILE="temp_pubs/key.pub"
	fi
fi

INTERNAL_HOSTNAME="$CONTAINER_NAME.internal"

# Get Correct Bridge/Network Name for the Container

if [ "$CONTAINER_TYPE" == "PR" ]; then
	BRIDGE="eno1.8"
	NETWORK="vmbr8"
	TAG="8"
	LEASE_FILE="PR-leases.conf"
elif [ "$CONTAINER_TYPE" == "BETA" ]; then
	BRIDGE="eno1.14"
        NETWORK="vmbr14"
	TAG="14"
	LEASE_FILE="Beta-leases.conf"
else
	BRIDGE="eno1.22"
        NETWORK="vmbr22"
	TAG="22"
	LEASE_FILE="Stable-leases.conf"
fi

# Create the Container

pct create $NEXTID local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname $CONTAINER_NAME \
  --cores 2 \
  --memory 2048 \
  --net0 name=$NETWORK,bridge=$NETWORK,tag=$TAG,ip=dhcp \
  --rootfs local-lvm:8 \
  --ssh-public-keys $PUBLIC_KEY_FILE \
  --password $CONTAINER_PASSWORD \
  --start 1

# Add Public Key to jump/ssh/authorized_keys

PUBLIC_KEY=$(cat $PUBLIC_KEY_FILE)

echo "$PUBLIC_KEY" >> /home/jump/.ssh/authorized_keys 

# Get LXC IP and Create new DNSMASQ lease

echo "⏳ Waiting for DHCP to allocate IP address to container..."
sleep 10

ALL_IPS=$(pct exec $NEXTID -- hostname -I)
IP=$( echo $ALL_IPS | awk '{print $1}') #get IPs of all hostnames and extract first one (will be in 10.8/10.14/10.22 class B subnet)

echo "Internal IP Address: $IP"
echo "Creating Address Lease"

ssh root@10.42.0.139 "echo 'address=/$INTERNAL_HOSTNAME/$IP' >> /etc/dnsmasq.d/${LEASE_FILE} && systemctl reload dnsmasq"

if [ "$CONTAINER_TYPE" == "STABLE" ]; then #create static lease
	MAC_ADDRESS=$(pct config $NEXTID | grep -oP 'hwaddr=\K[^,]+')
	ssh root@10.42.0.139 "echo 'dhcp-host=$MAC_ADDRESS,$IP,$CONTAINER_NAME' >> /etc/dnsmasq.d/${LEASE_FILE} && systemctl reload dnsmasq"
fi

echo "Added DNS Mapping for $CONTAINER_NAME"

# Add Container Details to JSON Hostname File

node hostnameRunner.js addHostname $CONTAINER_NAME $IP $CONTAINER_TYPE

# Container Details

echo -e "\n----------------------------------------"
echo -e "\n🎊 Your Container was Successfully Created. Details:\n"
echo "✅ Domain Name: $CONTAINER_NAME.mie.local"
echo "🔒 SSH Command [With SSH Keys]: ssh -A -J jump@$CONTAINER_NAME.mie.local,jump@jump-host.mie.local root@$CONTAINER_NAME.internal"
echo "🔒 SSH Command [Without SSH Keys]: ssh -J jump@$CONTAINER_NAME.mie.local,jump@jump-host.mie.local root@$CONTAINER_NAME.internal"
echo -e "\n----------------------------------------"
