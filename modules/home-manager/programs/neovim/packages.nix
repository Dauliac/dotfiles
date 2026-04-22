{
  flake.modules.homeManager.neovim-packages =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        alejandra
        dotenv-linter
        editorconfig-checker
        fd
        ghq
        hadolint
        helm-ls
        lazygit
        markdown-oxide
        nixfmt-rfc-style
        nixpkgs-fmt
        nodePackages.prettier
        nodePackages.typescript
        pyright
        python311Packages.pynvim
        ripgrep
        rust-analyzer
        clippy
        rustfmt
        harper
        shellcheck
        shellharden
        shfmt
        stylua
        supercollider
        terraform-ls
        typos
        xsel
        mermaid-cli
      ];
    };
}
