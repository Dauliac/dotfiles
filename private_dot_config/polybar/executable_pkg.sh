#!/bin/bash
yay -S
aur=$(yay -Pn)

if [[ "$aur" != "0" ]]
then
    echo "%{F#5b5b5b}%{F-} $aur"
else
    echo ""
fi;
