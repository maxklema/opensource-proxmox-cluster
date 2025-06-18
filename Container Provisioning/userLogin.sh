#!/bin/bash
# A script that handles Proxmox User Authentication
# Modified June 18th, 2025 by Maxwell Klema

read -p "Do you Have a Proxmox Account [Y/N]: " HAS_ACCOUNT

while [[ "$HAS_ACCOUNT" != "Y" && "$HAS_ACCOUNT" != "N" ]]; do
	echo "Invalid Option."
	read -p "Do you Have a Proxmox Account [Y/N]: " HAS_ACCOUNT
done

if [ "$HAS_ACCOUNT" == "Y" ]; then
	read -p "Enter Proxmox Username: " PROXMOX_USERNAME

else
	echo "Let's set up an account for you"
	read -p "Enter Username: " PROXMOX_USERNAME

	pveum useradd $PROXMOX_USERNAME@pve
	pveum passwd $PROXMOX_USERNAME@pve
fi

export $PROXMOX_USERNAME

