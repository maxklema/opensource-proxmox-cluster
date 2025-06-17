#!/bin/bash
# A script that appends a user's public key to the SSH jump host container to prevent them having to enter a password
# June 17th, 2025 Maxwell Klema

PUBLIC_KEY=$1
JUMP_HOST="jump-host.mie.local"

# SSH into the Jump Host

ssh root@"$JUMP_HOST" "echo '$PUBLIC_KEY' >> /home/jump/.ssh/authorized_keys && systemctl restart ssh"

exit 0

