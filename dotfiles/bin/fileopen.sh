#!/bin/bash
# Author: github.com/dauliac
# Date:   11/18/18
# Version: 0.0.1
# Description:


log=$HOME/.xlog
path=${1#file://}

if [ -d $path ]
then
    /usr/bin/${TERM_BIN} -e "/usr/bin/ranger $path" &>> $log
else
    /usr/bin/${TERM_BIN} -e "/usr/bin/ranger --selectfile=$path" &>> $log
fi
