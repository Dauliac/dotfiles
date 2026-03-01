{
  lib,
  ...
}:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (
      { pkgs, ... }:
      {
        programs.tmux = {
          enable = true;
          shell = "${pkgs.zsh}/bin/zsh";
          terminal = "tmux-256color";
          prefix = "C-a";
          mouse = true;
          keyMode = "vi";
          baseIndex = 1;
          escapeTime = 0;
          historyLimit = 50000;
          sensibleOnTop = true;
          clock24 = true;

          plugins = with pkgs.tmuxPlugins; [
            sensible
            yank
            vim-tmux-navigator
            {
              plugin = resurrect;
              extraConfig = ''
                set -g @resurrect-strategy-nvim 'session'
                set -g @resurrect-capture-pane-contents 'on'
              '';
            }
            {
              plugin = continuum;
              extraConfig = ''
                set -g @continuum-restore 'on'
                set -g @continuum-save-interval '10'
              '';
            }
          ];

          extraConfig = ''
            # True color support
            set -ag terminal-overrides ",xterm-256color:RGB"
            set -ag terminal-overrides ",alacritty:RGB"
            set -ag terminal-overrides ",ghostty:RGB"
            set -ag terminal-overrides ",*:Tc"

            # Splits (like zellij)
            bind | split-window -h -c "#{pane_current_path}"
            bind - split-window -v -c "#{pane_current_path}"
            bind c new-window -c "#{pane_current_path}"
            unbind '"'
            unbind %

            # Vim-like pane navigation
            bind h select-pane -L
            bind j select-pane -D
            bind k select-pane -U
            bind l select-pane -R

            # Resize panes
            bind -r H resize-pane -L 5
            bind -r J resize-pane -D 5
            bind -r K resize-pane -U 5
            bind -r L resize-pane -R 5

            # Reload config
            bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

            # Alt + number to switch windows (like zellij)
            bind -n M-1 select-window -t 1
            bind -n M-2 select-window -t 2
            bind -n M-3 select-window -t 3
            bind -n M-4 select-window -t 4
            bind -n M-5 select-window -t 5
            bind -n M-6 select-window -t 6
            bind -n M-7 select-window -t 7
            bind -n M-8 select-window -t 8
            bind -n M-9 select-window -t 9

            # Alt + h/l to switch windows
            bind -n M-h previous-window
            bind -n M-l next-window

            # Alt + n for new window
            bind -n M-n new-window -c "#{pane_current_path}"

            # Alt + z to zoom pane
            bind -n M-z resize-pane -Z

            # Focus events for vim
            set -g focus-events on

            # Status bar position
            set -g status-position top
          '';
        };

        # Catppuccin theme is auto-applied via catppuccin.tmux.enable in theme.nix
      }
    )
  ];
}
