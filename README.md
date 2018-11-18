# My rice dotfile:
## TODO:
- [ ] Need to update  `READMDE.md`
- [ ] Install [fd](https://github.com/sharkdp/fd)
- [ ] Update [fzf functions](https://github.com/junegunn/fzf/#tips)

## Vidaldi:
This patch is to have DRM on vivaldi (netflix, amazon prime..)
you need also to install `vivaldi-ffmpeg-extrea-bin`
```bash
    wget -O widevine.zip https://dl.google.com/widevine-cdm/`wget -qO- https://dl.google.com/widevine-cdm/current.txt`-linux-`uname -m | sed 's/x86_64/x64/;s/i[56]86/ia32/'`.zip
    unzip widevine.zip libwidevinecdm.so
    sudo install -Dm644 libwidevinecdm.so /opt/google/chrome/libwidevinecdm.so
```

## Vim:
This is instruction to recompile vim with all options
```bash
    git clone https://github.com/vim/vim.git /tmp/vim && cd /tmp/vim
    make distclean/src && cd ..
    ./configure  --with-features=huge --enable-pythoninterp=yes -enable-rubyinterp=yes  -enable-cscope --enable-fail-if-missing --enable-multibyte --enable-fontset -with-compiledby="GustavePate" --with-python-config-dir=/usr/lib/python2.7/config/ --with-ruby-command=/usr/bin/ruby --disable-gui --without-x
    make
    sudo make install
```

## Neomutt:

### Signature:

