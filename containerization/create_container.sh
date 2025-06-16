#!/bin/bash

GETNEXTID=$(pvesh get /cluster/nextid) #Get the next available LXC ID
NEXTID=$GETNEXTID

# Get Container Type (PR/Beta/Stable)
read -p "Enter Container Type (PR/BETA/STABLE): " CONTAINER_TYPE

while [[ "$CONTAINER_TYPE" != "PR" && "$CONTAINER_TYPE" != "BETA" && "$CONTAINER_TYPE" != "STABLE" ]];
do
	echo "Invalid Container Type. Must be \"PR\", \"BETA\", or \"STABLE\"."
	read -p "Enter Container Type (PR/BETA/STABLE): " CONTAINER_TYPE
done

# Gather Container Details
read -p "Enter Application Name (One-Word): " CONTAINER_NAME
read -sp "Enter Container Password: " CONTAINER_PASSWORD #password input silent


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
  --password $CONTAINER_PASSWORD \
  --start 1

# Get LXC IP and Create new DNSMASQ lease

echo "Waiting for DHCP to allocate IP address to container..."
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

