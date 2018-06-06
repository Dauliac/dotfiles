PATH="$HOME/.node_modules/bin:$PATH"
export npm_config_prefix=~/.node_modules

# Start X server
if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi

eval `/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg`
export SSH_AUTH_SOCK
export GPG_AGENT_INFO
