#!/bin/sh
vm=$(virsh list --state-running --name)
if [ ! -z "$vm" ]; then
    echo  $(virsh list --state-running --name | wc -l)
else
    echo ""
fi
