#!/bin/sh
vm=$(VBoxManage list runningvms)
if [ ! -z "$vm" ]; then
    echo  $(VBoxManage list runningvms | wc -l)
else
    echo ""
fi
