#!/bin/bash

pct create 208 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname mycontainer \
  --cores 2 \
  --memory 2048 \
  --net0 name=eno1.8,bridge=vmbr8,tag=8,ip=dhcp \
  --rootfs local-lvm:8 \
  --nameserver 10.42.0.139 \
  --password mysecurepassword \
  --start 1
