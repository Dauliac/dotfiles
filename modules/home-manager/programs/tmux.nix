{
  flake.modules.homeManager.tmux =
    {
      pkgs,
      lib,
      ...
    }:
    {
      # tmux-which-key config (XDG mode)
      # Use home.activation to create writable config (plugin needs to rebuild init.tmux)
      home.activation.tmuxWhichKeyConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                  CONFIG_DIR="$HOME/.config/tmux/plugins/tmux-which-key"
                  DATA_DIR="$HOME/.local/share/tmux/plugins/tmux-which-key"
                  mkdir -p "$CONFIG_DIR" "$DATA_DIR"

                  # Only write config if it doesn't exist or is a symlink (from old config)
                  if [ ! -f "$CONFIG_DIR/config.yaml" ] || [ -L "$CONFIG_DIR/config.yaml" ]; then
                    rm -f "$CONFIG_DIR/config.yaml"
                    cat > "$CONFIG_DIR/config.yaml" << 'WHICHKEYEOF'
        # yaml-language-server: $schema=config.schema.yaml
        command_alias_start_index: 200
        keybindings:
          prefix_table: Space
        title:
          style: align=centre,bold
          prefix: tmux
          prefix_style: fg=green,align=centre,bold
        position:
          x: C
          y: C
        custom_variables: []
        macros: []
        items:
          - name: Run command
            key: space
            command: command-prompt
          - name: Last window
            key: tab
            command: last-window
          - separator: true
          # Quick access splits at root level
          - name: Split right
            key: i
            command: "splitw -h -c #{pane_current_path}"
          - name: Split down
            key: u
            command: "splitw -v -c #{pane_current_path}"
          - name: New window
            key: n
            command: "neww -c #{pane_current_path}"
          - name: Zoom
            key: z
            command: resizep -Z
          - separator: true
          - name: Resize left
            key: H
            command: resizep -L 5
            transient: true
          - name: Resize down
            key: J
            command: resizep -D 5
            transient: true
          - name: Resize up
            key: K
            command: resizep -U 5
            transient: true
          - name: Resize right
            key: L
            command: resizep -R 5
            transient: true
          - separator: true
          - name: +Windows
            key: w
            menu:
              - name: Choose
                key: w
                command: choose-tree -Zw
              - name: Previous
                key: p
                command: previous-window
              - name: Next
                key: n
                command: next-window
              - name: New
                key: c
                command: "neww -c #{pane_current_path}"
              - separator: true
              - name: Split right
                key: i
                command: "splitw -h -c #{pane_current_path}"
              - name: Split down
                key: u
                command: "splitw -v -c #{pane_current_path}"
              - separator: true
              - name: Rename
                key: r
                command: command-prompt -I "#W" "renamew -- \"%%\""
              - name: Kill
                key: x
                command: 'confirm -p "Kill window? (y/n)" killw'
          - name: +Panes
            key: p
            menu:
              - name: Split right
                key: i
                command: "splitw -h -c #{pane_current_path}"
              - name: Split down
                key: u
                command: "splitw -v -c #{pane_current_path}"
              - separator: true
              - name: Left
                key: h
                command: selectp -L
              - name: Down
                key: j
                command: selectp -D
              - name: Up
                key: k
                command: selectp -U
              - name: Right
                key: l
                command: selectp -R
              - separator: true
              - name: Zoom
                key: z
                command: resizep -Z
              - name: Resize left
                key: H
                command: resizep -L 5
                transient: true
              - name: Resize down
                key: J
                command: resizep -D 5
                transient: true
              - name: Resize up
                key: K
                command: resizep -U 5
                transient: true
              - name: Resize right
                key: L
                command: resizep -R 5
                transient: true
              - separator: true
              - name: Kill
                key: x
                command: 'confirm -p "Kill pane? (y/n)" killp'
          - name: +Sessions
            key: s
            menu:
              - name: Choose
                key: s
                command: choose-tree -Zs
              - name: New
                key: n
                command: command-prompt -p "Session name:" "new-session -s '%%'"
              - name: Detach
                key: d
                command: detach
              - name: Rename
                key: r
                command: command-prompt -I "#S" "rename-session -- \"%%\""
          - name: Copy mode
            key: c
            command: copy-mode
          - separator: true
          - name: Reload config
            key: r
            command: source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
          - name: Keys
            key: "?"
            command: list-keys -N
        WHICHKEYEOF
                  fi

                  # Fix init.tmux permissions if it exists (plugin copies from nix store as read-only)
                  if [ -f "$DATA_DIR/init.tmux" ]; then
                    chmod 644 "$DATA_DIR/init.tmux"
                  fi
      '';

      programs.tmux = {
        enable = true;
        shell = "${pkgs.zsh}/bin/zsh";
        terminal = "tmux-256color";
        prefix = "C-a";
        mouse = true;
        keyMode = "vi";
        baseIndex = 1;
        escapeTime = 0;
        historyLimit = 100000; # Match zellij scroll_buffer_size
        sensibleOnTop = true;
        clock24 = true;

        plugins = with pkgs.tmuxPlugins; [
          sensible
          yank
          vim-tmux-navigator
          copycat # Enhanced searching
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
          {
            # Which-key style popup menu for tmux keybindings
            # Press prefix + Space to show menu
            plugin = tmux-which-key;
            extraConfig = ''
              # Required for Nix: use XDG dirs instead of read-only nix store
              set -g @tmux-which-key-xdg-enable 1
            '';
          }
        ];

        extraConfig = ''
          # Fix: home-manager binds "C-a send-prefix" in root table,
          # which intercepts the prefix key. Remove it so C-a works as prefix.
          unbind -n C-a
          bind C-a send-prefix

          # True color support
          set -ag terminal-overrides ",xterm-256color:RGB"
          set -ag terminal-overrides ",alacritty:RGB"
          set -ag terminal-overrides ",ghostty:RGB"
          set -ag terminal-overrides ",*:Tc"

          # Copy on select (like zellij copy_on_select)
          set -g @yank_selection_mouse 'clipboard'
          set -g set-clipboard on

          # Pane borders off (like zellij pane_frames false)
          set -g pane-border-status off
          set -g pane-border-lines single

          # Splits with prefix (like zellij Ctrl+p then d/r)
          bind u split-window -v -c "#{pane_current_path}"  # Down split (like zellij tmux mode 'u')
          bind i split-window -h -c "#{pane_current_path}"  # Right split (like zellij tmux mode 'i')
          bind | split-window -h -c "#{pane_current_path}"
          bind - split-window -v -c "#{pane_current_path}"
          bind c new-window -c "#{pane_current_path}"
          unbind '"'
          unbind %

          # Vim-like pane navigation (prefix + hjkl)
          bind h select-pane -L
          bind j select-pane -D
          bind k select-pane -U
          bind l select-pane -R

          # Resize panes (prefix + HJKL)
          bind -r H resize-pane -L 5
          bind -r J resize-pane -D 5
          bind -r K resize-pane -U 5
          bind -r L resize-pane -R 5

          # Reload config
          bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

          # Close pane (like zellij 'x' in pane mode)
          bind x kill-pane

          # Zoom/fullscreen toggle (like zellij 'f' in pane mode)
          bind z resize-pane -Z

          # Detach (like zellij 'd' in session mode)
          bind d detach-client

          # Rename window (like zellij 'r' in tab mode)
          bind , command-prompt -I "#W" "rename-window '%%'"

          # Next/previous tab (like zellij 'n'/'p' in tmux mode)
          bind n next-window
          bind p previous-window

          # Switch focus (like zellij 'o' in tmux mode)
          bind o select-pane -t :.+

          # Alt + number to switch windows (like zellij tab mode 1-9)
          bind -n M-1 select-window -t 1
          bind -n M-2 select-window -t 2
          bind -n M-3 select-window -t 3
          bind -n M-4 select-window -t 4
          bind -n M-5 select-window -t 5
          bind -n M-6 select-window -t 6
          bind -n M-7 select-window -t 7
          bind -n M-8 select-window -t 8
          bind -n M-9 select-window -t 9

          # Alt + h/l to switch windows (like zellij Alt+h/l MoveFocusOrTab)
          bind -n M-h previous-window
          bind -n M-l next-window

          # Alt + j/k to switch panes (like zellij Alt+j/k MoveFocus)
          bind -n M-j select-pane -D
          bind -n M-k select-pane -U

          # Alt + n for new pane (like zellij Alt+n NewPane)
          bind -n M-n split-window -h -c "#{pane_current_path}"

          # Alt + c for new pane down (like zellij Alt+c NewPane Down)
          bind -n M-c split-window -v -c "#{pane_current_path}"

          # Alt + z to zoom pane (like zellij 'z' ToggleFocusFullscreen)
          bind -n M-z resize-pane -Z

          # Alt + =/- for resize (like zellij Alt+=/- Resize)
          bind -n M-= resize-pane -U 2
          bind -n M-- resize-pane -D 2

          # Copy mode with prefix+[ (like zellij scroll mode)
          bind [ copy-mode
          # In copy mode, use vim bindings
          bind -T copy-mode-vi v send -X begin-selection
          bind -T copy-mode-vi y send -X copy-selection-and-cancel
          bind -T copy-mode-vi Escape send -X cancel

          # Search in copy mode (like zellij 's' in scroll mode)
          bind -T copy-mode-vi / command-prompt -i -p "search down:" "send -X search-forward-incremental \"%%%\""
          bind -T copy-mode-vi ? command-prompt -i -p "search up:" "send -X search-backward-incremental \"%%%\""

          # Half page scroll (like zellij 'd'/'u' in scroll mode)
          bind -T copy-mode-vi d send -X halfpage-down
          bind -T copy-mode-vi u send -X halfpage-up

          # Focus events for vim
          set -g focus-events on

          # Allow passthrough for image display (image.nvim, kitty graphics protocol)
          set -g allow-passthrough on

          # Status bar position (top like zellij tab-bar)
          set -g status-position top

          # Aggressive resize for better multi-monitor support
          setw -g aggressive-resize on
        '';
      };

      # Catppuccin theme is auto-applied via catppuccin.tmux.enable in theme.nix
    };
}
