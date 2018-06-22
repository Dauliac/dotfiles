#!/usr/bin/bash
# Run me to backup dotfiles
if [ ! -d "${HOME}/.config" ]; then
    mkdir "${HOME}/.config"
fi
cd dotfiles
for dot in *; do
    echo ${dot} ===========
    if [ -d "${dot}" ]; then
        if [ -d "${HOME}/.config/${dot}" ]; then
            mv "${HOME}/.config/${dot}" "${HOME}/.config/${dot}.orig" && \
            echo CREATE ${dot}.orig
        fi
        mkdir "${HOME}/.config/${dot}" && \
        cd ${dot}
        for dotbrick in *; do
            echo mv config file ${dotbrick}
            ln "${dotbrick}" "${HOME}/.config/${dot}" && \
            echo create ${dotbrick}
        done
        echo DONE: ${dot}
        cd ..
    else
        if [ -f "${dot}" ]; then
            if [ -f "${HOME}/.${dot}" ]; then
                mv "${HOME}/.${dot}" "${HOME}/.${dot}.orig" && \
                echo CREATE ${dot}.orig
            fi
            ln "${dot}" "${HOME}/.${dot}" && \
            echo DONE: ${dot}
        else
            echo ERROR: ${dot} is not valid
        fi
    fi
done
