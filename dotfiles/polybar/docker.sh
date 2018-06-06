#!/bin/sh
containers=$(docker ps -aq 2> /dev/null)
if [ ! -z "$containers" ]; then
    echo   $(docker ps -aq | wc -l)
else
    echo ""
fi
