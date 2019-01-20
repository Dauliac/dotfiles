#!/bin/bash
# Author: github.com/dauliac
# Date:   12/31/18
# Version: 0.0.1
# Description: cd on current folder when quit nnn

export NNN_TMPFILE="/tmp/nnn"

n()
{
        nnn "$@"

        if [ -f $NNN_TMPFILE ]; then
                . $NNN_TMPFILE
                rm -f $NNN_TMPFILE > /dev/null
        fi
}
