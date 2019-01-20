#!/bin/bash
# Author: github.com/dauliac
# Date:   01/20/19
# Version: 0.0.1
# Description:

prefix="[dotfiles]"

CHEZMOI_SOURCES="https://github.com/twpayne/chezmoi/releases/download/v1.2.0/chezmoi_1.2.0_linux_amd64.tar.gz"
SOURCES_PATH="/tmp/chezmoi.tar.gz"
TMP_DEST="/tmp/chezmoi"
BIN_PATH="$HOME/.local/bin"

if [ ! -f $SOURCES_PATH ]; then
    echo ${prefix} Downloading \`chezmoi\`
    curl -o  ${SOURCES_PATH} -L -O https://github.com/twpayne/chezmoi/releases/download/v1.2.0/chezmoi_1.2.0_linux_amd64.tar.gz
else
    echo ${prefix} \`chezmoi\` sources are already present
fi

echo ${prefix} Removing old sources
rm -Rf $TMP_DEST
mkdir -p $TMP_DEST
echo ${prefix} Extract new sources
tar -xf ${SOURCES_PATH} -C $TMP_DEST
echo ${prefix} Adding binary to local '$PATH'
mv ${TMP_DEST}/chezmoi ${BIN_PATH}/

