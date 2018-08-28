# My rice dotfile:
## TODO:
- [ ] Need to update  `READMDE.md`
- [ ] Install [fd](https://github.com/sharkdp/fd)
- [ ] Update [fzf functions](https://github.com/junegunn/fzf/#tips)

## Vidaldi:
This patch is to have DRM on vivaldi (netflix, amazon prime..)
```bash
    wget -O widevine.zip https://dl.google.com/widevine-cdm/`wget -qO- https://dl.google.com/widevine-cdm/current.txt`-linux-`uname -m | sed 's/x86_64/x64/;s/i[56]86/ia32/'`.zip
    unzip widevine.zip libwidevinecdm.so
    sudo install -Dm644 libwidevinecdm.so /opt/google/chrome/libwidevinecdm.so
```

## Vim:
This is instruction to recompile vim with all options
