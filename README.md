#github.com/Dauliac/dotfiles
My rices dotfiles: now with [`chezmoi`](https://github.com/twpayne/chezmoi)

## Install

```bash
git clone git@github.com:Dauliac/dotfiles.git ~/.local/share/chezmoi
```

Install `chezmoi`:
```bash
cd ~/.local/share/chezmoi
make install
```

Create a `./config/chezmoi/chezmoi.yaml` with:
```bash
chezmoi edit-config
```

And add:
```yaml
data:
  font: "Monoid Nerd Font Mono"
  git:
    email: "<git email>"
    name: "<git name>"
    token: "<git token>"
  colors:
    hard_background: "1d2021"
    soft_background: "32302f"
    background: "282828"
    foreground: "ebdbb2"
    black: "282828"
    dark_grey: "ebdbb2"
    red : "fb4934"
    dark_red: "cc241d"
    dark_green: "98971a"
    green: "b8bb26"
    dark_yellow: "d79921"
    yellow: "fabd2f"
    dark_blue: "458588"
    blue: "83a598"
    dark_magenta: "b16286"
    magenta: "d3869b"
    dark_cyan: "689d6a"
    cyan: "8ec07c"
    light_grey: "a89984"
    dark_white: "ebdbba"
    white: "ffffff"
  monitors:
    one: "HDMI-1"
    two: "HDMI-2"
  defaults:
    term: "/usr/bin/alacritty"
    image: "/usr/bin/feh"
    pdf: "/usr/bin/zathura"
    browser: "/usr/bin/firefox"
    text: "/usr/bin/vim"
    file: "/usr/bin/nnn"
```

Deploy `chezmoi` configs:
```bash
make update
```
