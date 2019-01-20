#!/bin/bash
# Author: github.com/dauliac
# Date:   12/31/18
# Version: 0.0.1
# Description: Copier into xclip for nnn

cat ~/.nnncp | xargs -0 | xsel -bi
