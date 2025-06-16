# /usr/local/bin/automatic-ssh-proxy.sh
# No longer in use. Used as a substitle to Jump Hosts, but not IDE ssh extension friendly

#!/bin/bash

echo -e "\n\nMedical Informatics Engineering Container Cluster\n"

echo "Welcome $USER. Let's SSH into your Application."
read -e -p "Enter your appname: " APPNAME
echo "Attempting to SSH into $appname.mie.local..."

TARGET_HOST="${APPNAME}.internal"

# Forward the SSH session to target container (host)
exec ssh -o StrictHostKeyChecking=no -tt "${USER}@${TARGET_HOST}"
