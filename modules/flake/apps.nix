{ inputs, ... }:
let
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs.legacyPackages.${system};

  # Script to set a user's password
  setPasswordScript = pkgs.writeShellScript "set-password" ''
    set -euo pipefail

    REPO_ROOT="$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
    PASSWORDS_DIR="$REPO_ROOT/secrets/passwords"

    # Ensure passwords directory exists
    mkdir -p "$PASSWORDS_DIR"

    echo "=== NixOS User Password Manager ==="
    echo ""

    # Get username
    if [ -n "''${1:-}" ]; then
      USERNAME="$1"
    else
      echo "Available users: gary, dauliac, spongebob"
      echo -n "Enter username: "
      read -r USERNAME
    fi

    if [ -z "$USERNAME" ]; then
      echo "Error: Username cannot be empty"
      exit 1
    fi

    PASSWORD_FILE="$PASSWORDS_DIR/$USERNAME.enc"

    # Get password
    echo -n "Enter password for $USERNAME: "
    read -rs PASSWORD
    echo ""

    if [ -z "$PASSWORD" ]; then
      echo "Error: Password cannot be empty"
      exit 1
    fi

    echo -n "Confirm password: "
    read -rs PASSWORD_CONFIRM
    echo ""

    if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
      echo "Error: Passwords do not match"
      exit 1
    fi

    # Generate SHA-512 hash
    echo "Generating password hash..."
    HASH=$(echo "$PASSWORD" | ${pkgs.mkpasswd}/bin/mkpasswd -m sha-512 -s)

    # Encrypt with sops (required for sops-nix compatibility)
    echo "Encrypting password for $USERNAME..."
    # Create temp file in the target location so path_regex matches
    TMPFILE="$PASSWORDS_DIR/.tmp-$USERNAME.enc"
    echo -n "$HASH" > "$TMPFILE"

    # Encrypt using sops with the repo's .sops.yaml
    cd "$REPO_ROOT"
    ${pkgs.sops}/bin/sops --encrypt \
      --input-type binary \
      --output-type binary \
      "$TMPFILE" > "$PASSWORD_FILE"

    rm -f "$TMPFILE"

    echo ""
    echo "Password encrypted and saved to: $PASSWORD_FILE"
    echo ""
    echo "Next steps:"
    echo "  1. Commit the encrypted file: git add $PASSWORD_FILE"
    echo "  2. Rebuild NixOS: nixos-rebuild switch --flake ."
  '';

  # Script to show a user's password hash (for debugging)
  showPasswordScript = pkgs.writeShellScript "show-password" ''
    set -euo pipefail

    REPO_ROOT="$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
    PASSWORDS_DIR="$REPO_ROOT/secrets/passwords"

    if [ -z "''${1:-}" ]; then
      echo "Usage: nix run .#show-password -- <username>"
      echo "Available password files:"
      ls -1 "$PASSWORDS_DIR"/*.enc 2>/dev/null | xargs -I{} basename {} .enc || echo "  (none)"
      exit 1
    fi

    USERNAME="$1"
    PASSWORD_FILE="$PASSWORDS_DIR/$USERNAME.enc"

    if [ ! -f "$PASSWORD_FILE" ]; then
      echo "Error: No password file found for $USERNAME"
      echo "Run: nix run .#set-password -- $USERNAME"
      exit 1
    fi

    echo "Decrypted password hash for $USERNAME:"
    SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/dotfiles.txt" \
      ${pkgs.sops}/bin/sops --decrypt \
      --input-type binary \
      --output-type binary \
      "$PASSWORD_FILE"
  '';

  # Script to list all password files
  listPasswordsScript = pkgs.writeShellScript "list-passwords" ''
    set -euo pipefail

    REPO_ROOT="$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
    PASSWORDS_DIR="$REPO_ROOT/secrets/passwords"

    echo "=== Encrypted Password Files ==="
    echo ""

    if [ -d "$PASSWORDS_DIR" ]; then
      for f in "$PASSWORDS_DIR"/*.enc; do
        if [ -f "$f" ]; then
          USERNAME=$(basename "$f" .enc)
          MODIFIED=$(stat -c %y "$f" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
          echo "  $USERNAME (modified: $MODIFIED)"
        fi
      done
    else
      echo "  No passwords directory found"
      echo "  Run: nix run .#set-password"
    fi
  '';

  passwordApps = {
    set-password = {
      type = "app";
      program = toString setPasswordScript;
    };
    show-password = {
      type = "app";
      program = toString showPasswordScript;
    };
    list-passwords = {
      type = "app";
      program = toString listPasswordsScript;
    };
  };
in
{
  flake.apps.${system} = passwordApps;
}
