#!/bin/bash
# Break-glass re-deploy: restores nix PATH and runs `xi system switch .`.
#
# Use when your shell has lost access to nix bins (e.g. after a home-manager
# evaluation dropped /nix/var/nix/profiles/default/bin from PATH). This
# script sources the system-wide profile.d entries so it works even when
# your interactive shell is broken.
#
# Run from the repo root:
#     bash redeploy.sh
# or, after chmod +x redeploy.sh:
#     ./redeploy.sh

set -u

# Log everything to redeploy.log so the crash output survives even when
# clipboard/terminal is broken.
LOG=redeploy.log
exec > >(tee "$LOG") 2>&1
echo "=== redeploy.sh started at $(date -Is) ==="

# 1. Restore system nix PATH — nix-daemon.sh prepends ~/.nix-profile/bin
#    and /nix/var/nix/profiles/default/bin.
if [ -f /etc/profile.d/nix.sh ]; then
  # shellcheck source=/dev/null
  . /etc/profile.d/nix.sh
  echo "sourced /etc/profile.d/nix.sh"
else
  echo "error: /etc/profile.d/nix.sh not found — nix installer is broken"
  exit 1
fi

# 2. Restore system-manager profile PATH additions if present.
if [ -f /etc/profile.d/system-manager-path.sh ]; then
  # shellcheck source=/dev/null
  . /etc/profile.d/system-manager-path.sh
  echo "sourced /etc/profile.d/system-manager-path.sh"
fi

echo "PATH after sourcing:"
echo "$PATH" | tr ':' '\n' | sed 's/^/  /'

# 3. Locate xi; fall back to `nix run` from GitHub if not installed anywhere.
if command -v xi >/dev/null 2>&1; then
  xi_bin=$(command -v xi)
elif [ -x "$HOME/.nix-profile/bin/xi" ]; then
  xi_bin="$HOME/.nix-profile/bin/xi"
else
  echo "xi not available locally — running via nix run from GitHub"
  set +e
  /nix/var/nix/profiles/default/bin/nix run \
    --extra-experimental-features 'nix-command flakes' \
    'github:Dauliac/xi' -- system switch .
  rc=$?
  echo "=== redeploy.sh exited with $rc ==="
  echo "log written to $LOG"
  exit $rc
fi

echo "using xi: $xi_bin"
set +e
"$xi_bin" system switch .
rc=$?
echo "=== redeploy.sh exited with $rc ==="
echo "log written to $LOG"
exit $rc
