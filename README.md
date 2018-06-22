#My rice dotfile

## Install
'''bash
    git clone https://github.com/Dauliac/dotfiles.git .dotfiles
    cd .dotfiles
    ./install.sh
'''
## How that is working
The `./install.sh` script create physical link beetwin the git `.dotfiles` folder and specific configs paths.

## Maintenance
Phisicals links allow you to edit **dotfiles** directly from the `.dotfiles` folder.
You can edit your directly in `.dotfiles/dotfiles` folder.
You need to create your **dotfile** without the "." prefix and your `.config/config_folder` in folder.

## Todo
Execute ./install from any context path.
Manage `.config/file` and not only folders.
Update screenshots or remove them.
