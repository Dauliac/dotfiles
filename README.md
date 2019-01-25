#github.com/Dauliac/dotfiles
My rices dotfiles: now with [`chezmoi`](https://github.com/twpayne/chezmoi)

## Install

```bash
git clone git@github.com:Dauliac/dotfiles.git ~/.local/share/chezmoi
```

Create a `./config/chezmoi/chezmoi.yaml` with:
```bash
chezmoi edit-config
```

And add:
```yaml
data:
  git:
    email: "<git email>"
    name: "<git name>"
    token: "<git token>"
  monitors:
    one: <screen 1>
    two: <screen 2>
  colors:
    hard_background: "#1d2021"
    soft_background: "#32302f"
    background: "#282828"
    foreground: "#ebdbb2"
    black: "#282828"
    dark_gray: "#ebdbb2"
    red: "#cc241d"
    light_red : "#fb4934"
    dark_green: "#98971a"
    green: "#b8bb26"
    dark_yellow: "#d79921"
    yellow: "#fabd2f"
    dark_blue: "#458588"
    blue: "#83a598"
    dark_magenta: "#b16286"
    magenta: "#d3869b"
    dark_cyan: "#689d6a"
    cyan: "#8ec07c"
    light_grey: "#a89984"
    dark_white: "#ebdbba"
    white: "#fff"
```

To conclue modifications:
```bash
chezmoi apply -v
```
