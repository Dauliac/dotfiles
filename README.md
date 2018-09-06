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
### Doc:
#### Basics:
TODO
| Map | Action |
|-----|--------|

#### Netrw:
| Map | Action |
|-----|--------|
| &lt;F1&gt; | Causes Netrw to issue help |
| &lt;cr&gt; | Netrw will enter the directory or read the file |
| &lt;del&gt; | Netrw will attempt to remove the file/directory |
| - | Makes Netrw go up one directory |
| a | Toggles between normal display, hiding (suppress display of files matching g:netrw_list_hide) showing (display only files which match g:netrw_list_hide) |
| c | Make browsing directory the current directory |
| C | Setting the editing window |
| d | Make a directory |
| D | Attempt to remove the file(s)/directory(ies) |
| gb | Go to previous bookmarked directory |
| gh | Quick hide/unhide of dot-files |
| &lt;c-h&gt; | Edit file hiding list |
| i | Cycle between thin, long, wide and tree listings |
| &lt;c-l&gt; | Causes Netrw to refresh the directory listing |
| mb | Bookmark current directory |
| mc | Copy marked files to marked-file target directory |
| md | Apply diff to marked files (up to 3) |
| me | Place marked files on arg list and edit them |
| mf | Mark a file |
| mh | Toggle marked file suffices' presence on hiding list |
| mm | Move marked files to marked-file target directory |
| mp | Print marked files |
| mr | Mark files satisfying a shell-style |regexp| |
| mt | Current browsing directory becomes markfile target |
| mT | Apply ctags to marked files |
| mu | Unmark all marked files |
| mx | Apply arbitrary shell command to marked files |
| mz | Compress/decompress marked files |
| o | Enter the file/directory under the cursor in a new browser window. A horizontal split is used. |
| O | Obtain a file specified by cursor |
| p | Preview the file |
| P | Browse in the previously used window |
| qb | List bookmarked directories and history |
| qf | Display information on file |
| r | Reverse sorting order |
| R | Rename the designed file(s)/directory(ies) |
| s | Select sorting style: by name, time or file size |
| S | Specify suffix priority for name-sorting |
| t | Enter the file/directory under the cursor in a new tab |
| u | Change to recently-visited directory |
| U | Change to subsequently-visited directory |
| v | Enter the file/directory under the cursor in a new browser window. A vertical split is used. |
| x | View file with an associated program |
| X | Execute filename under cursor via |system()| |
| % | Open a new file in netrw's current directory |
