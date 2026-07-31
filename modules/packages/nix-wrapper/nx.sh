#!/usr/bin/env bash
# nx - A nix CLI wrapper with better alternatives
#
# Replaces common nix commands with more user-friendly alternatives:
#   search  -> neix (fast local search with TUI)
#   build   -> nom (nix-output-monitor for pretty output)
#   shell   -> nom shell
#   develop -> nom develop
#   tree    -> nix-tree (interactive dependency browser)
#   diff    -> nix-diff (explain derivation differences)
#   lint    -> statix + deadnix
#   docs    -> manix (search documentation)
#   why     -> nix why-depends with better formatting
#   compare -> nvd (compare generations/closures)
#   run     -> comma-like behavior
#   os      -> xi os (better nixos-rebuild)
#   home    -> xi home (better home-manager)
#   locate  -> nix-locate (find package providing a file)
#   health  -> flake-checker (flake.lock health checks)
#   gc      -> nix-du + nix-collect-garbage (smart cleanup)
#   size    -> closure size analysis
#   url     -> nurl (generate fetcher from URL)

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

show_help() {
  cat <<'EOF'
nx - A nix CLI wrapper with better alternatives

USAGE:
    nx <command> [args...]

SEARCH & DISCOVERY:
    search <query>       Search packages with neix (TUI)
    locate <file>        Find which package provides a file (nix-locate)
    docs <query>         Search nix documentation (manix)

BUILD & DEVELOP:
    build [args...]      Build with nix-output-monitor (pretty output)
    shell [args...]      Shell with nix-output-monitor
    develop [args...]    Develop with nix-output-monitor
    watch <cmd...>       Run any nix command with pretty output via nom

ANALYSIS & INSPECTION:
    tree [path]          Interactive dependency browser (nix-tree)
    diff <drv1> <drv2>   Explain why derivations differ (nix-diff)
    compare <p1> <p2>    Compare store paths/generations (nvd)
    size [path]          Show closure size (path-info -Sh)
    why <pkg> <dep>      Why does package depend on dep

CODE QUALITY:
    lint [path]          Run statix + deadnix on nix files
    health [path]        Check flake.lock health (flake-checker)

SYSTEM MANAGEMENT:
    os <cmd> [args...]   NixOS rebuild with xi (switch, boot, test...)
    home <cmd> [args...] Home-manager with xi (switch, build...)
    gc [--dry-run]       Smart garbage collection with size analysis
    clean                Alias for gc

PACKAGE CREATION:
    url <repo-url>       Generate nix fetcher from URL (nurl)

PASSTHROUGH (forwarded to nix):
    flake, profile, registry, store, derivation, hash,
    key, nar, path-info, print-dev-env, realisation,
    bundle, copy, daemon, edit, eval, log, repl,
    run, upgrade-nix, doctor, show-config, fmt

SPECIAL:
    ,<pkg>               Run package directly (comma)
    --help, -h           Show this help
    --version, -v        Show version info

EXAMPLES:
    nx search ripgrep           # Search packages with TUI
    nx locate bin/rg            # Find package providing 'rg'
    nx build .#myPackage        # Build with pretty output
    nx tree /nix/store/...      # Browse dependencies
    nx lint ./my-config.nix     # Check for issues
    nx health                   # Check flake.lock freshness
    nx gc --dry-run             # Preview what would be collected
    nx url github:owner/repo    # Generate fetcher expression
    nx os switch                # Rebuild NixOS with diff
    nx home switch              # Rebuild home-manager

EOF
}

show_version() {
  echo -e "${BOLD}nx${NC} - nix wrapper v1.1.0"
  echo ""
  echo "Bundled tools:"
  echo -e "  ${CYAN}neix${NC}          - $(neix --version 2>/dev/null || echo 'fast package search')"
  echo -e "  ${CYAN}nom${NC}           - $(nom --version 2>/dev/null || echo 'nix-output-monitor')"
  echo -e "  ${CYAN}nix-tree${NC}      - $(nix-tree --version 2>/dev/null || echo 'dependency browser')"
  echo -e "  ${CYAN}nvd${NC}           - $(nvd --version 2>/dev/null || echo 'closure differ')"
  echo -e "  ${CYAN}manix${NC}         - $(manix --version 2>/dev/null || echo 'documentation search')"
  echo -e "  ${CYAN}statix${NC}        - $(statix --version 2>/dev/null || echo 'nix linter')"
  echo -e "  ${CYAN}deadnix${NC}       - $(deadnix --version 2>/dev/null || echo 'dead code finder')"
  echo -e "  ${CYAN}nix-diff${NC}      - derivation differ"
  echo -e "  ${CYAN}xi${NC}            - $(xi --version 2>/dev/null || echo 'nix helper')"
  echo -e "  ${CYAN}nix-locate${NC}    - $(nix-locate --version 2>/dev/null || echo 'file locator')"
  echo -e "  ${CYAN}flake-checker${NC} - $(flake-checker --version 2>/dev/null || echo 'flake health')"
  echo -e "  ${CYAN}nix-du${NC}        - $(nix-du --version 2>/dev/null || echo 'store analyzer')"
  echo -e "  ${CYAN}nurl${NC}          - $(nurl --version 2>/dev/null || echo 'fetcher generator')"
}

cmd_search() {
  if [[ $# -eq 0 ]]; then
    echo -e "${BLUE}Launching neix...${NC}"
    neix
  else
    neix "$@"
  fi
}

cmd_build() {
  echo -e "${GREEN}Building with nix-output-monitor...${NC}"
  nom build "$@"
}

cmd_shell() {
  echo -e "${GREEN}Starting shell with nix-output-monitor...${NC}"
  nom shell "$@"
}

cmd_develop() {
  echo -e "${GREEN}Starting develop shell with nix-output-monitor...${NC}"
  nom develop "$@"
}

cmd_tree() {
  if [[ $# -eq 0 ]]; then
    # Try to find a result link or flake output
    if [[ -L "./result" ]]; then
      echo -e "${BLUE}Browsing ./result dependencies...${NC}"
      nix-tree ./result
    else
      echo -e "${YELLOW}Usage: nx tree <store-path|./result|.#package>${NC}"
      echo "Examples:"
      echo "  nx tree ./result"
      echo "  nx tree .#myPackage"
      echo "  nx tree /nix/store/..."
    fi
  else
    nix-tree "$@"
  fi
}

cmd_diff() {
  if [[ $# -lt 2 ]]; then
    echo -e "${YELLOW}Usage: nx diff <derivation1> <derivation2>${NC}"
    echo "Example: nx diff /nix/store/...-foo.drv /nix/store/...-bar.drv"
    exit 1
  fi
  nix-diff "$@"
}

cmd_lint() {
  local target="${1:-.}"
  echo -e "${BLUE}Running statix check...${NC}"
  statix check "$target" || true
  echo ""
  echo -e "${BLUE}Running deadnix...${NC}"
  deadnix "$target" || true
}

cmd_docs() {
  if [[ $# -eq 0 ]]; then
    echo -e "${YELLOW}Usage: nx docs <query>${NC}"
    echo "Example: nx docs mkDerivation"
    exit 1
  fi
  manix "$@"
}

cmd_compare() {
  if [[ $# -lt 2 ]]; then
    echo -e "${YELLOW}Usage: nx compare <path1> <path2>${NC}"
    echo "Examples:"
    echo "  nx compare /nix/var/nix/profiles/system-42-link /nix/var/nix/profiles/system-43-link"
    echo "  nx compare ./result ./result-2"
    exit 1
  fi
  nvd diff "$@"
}

cmd_os() {
  if [[ $# -eq 0 ]]; then
    echo -e "${YELLOW}Usage: nx os <command> [args...]${NC}"
    echo "Commands: switch, boot, test, build, dry, repl"
    exit 1
  fi
  xi os "$@"
}

cmd_home() {
  if [[ $# -eq 0 ]]; then
    echo -e "${YELLOW}Usage: nx home <command> [args...]${NC}"
    echo "Commands: switch, build"
    exit 1
  fi
  xi home "$@"
}

cmd_comma() {
  local pkg="${1#,}"
  shift || true
  echo -e "${GREEN}Running $pkg via comma...${NC}"
  comma "$pkg" "$@"
}

cmd_locate() {
  if [[ $# -eq 0 ]]; then
    echo -e "${YELLOW}Usage: nx locate <file-pattern>${NC}"
    echo "Examples:"
    echo "  nx locate bin/rg        # Find package with 'rg' binary"
    echo "  nx locate libssl.so     # Find package with libssl"
    exit 1
  fi
  nix-locate "$@"
}

cmd_health() {
  local target="${1:-.}"
  local lock_path="$target/flake.lock"
  if [[ $target == *.lock ]]; then
    lock_path="$target"
  elif [[ -f "$target/flake.lock" ]]; then
    lock_path="$target/flake.lock"
  elif [[ -f "flake.lock" ]]; then
    lock_path="flake.lock"
  else
    echo -e "${YELLOW}No flake.lock found${NC}"
    exit 1
  fi
  echo -e "${BLUE}Checking flake health: $lock_path${NC}"
  flake-checker "$lock_path"
}

cmd_gc() {
  local dry_run=false
  for arg in "$@"; do
    if [[ $arg == "--dry-run" ]] || [[ $arg == "-n" ]]; then
      dry_run=true
    fi
  done

  echo -e "${BLUE}Analyzing nix store usage...${NC}"
  echo ""
  nix-du -s 2>/dev/null | head -20 || true
  echo ""

  if [[ $dry_run == true ]]; then
    echo -e "${YELLOW}Dry run - would collect:${NC}"
    nix-collect-garbage --dry-run 2>&1 | tail -5
  else
    echo -e "${GREEN}Running garbage collection...${NC}"
    nix-collect-garbage -d
    echo ""
    echo -e "${GREEN}Store optimized!${NC}"
  fi
}

cmd_size() {
  local target="${1:-./result}"
  if [[ ! -e $target ]]; then
    echo -e "${YELLOW}Usage: nx size <store-path|./result>${NC}"
    exit 1
  fi
  echo -e "${BLUE}Closure size for $target:${NC}"
  nix path-info -Sh "$target"
  echo ""
  echo -e "${BLUE}Top dependencies by size:${NC}"
  nix path-info -rSh "$target" 2>/dev/null | sort -hk2 | tail -10
}

cmd_url() {
  if [[ $# -eq 0 ]]; then
    echo -e "${YELLOW}Usage: nx url <repository-url>${NC}"
    echo "Examples:"
    echo "  nx url https://github.com/owner/repo"
    echo "  nx url github:owner/repo"
    exit 1
  fi
  nurl "$@"
}

cmd_why() {
  if [[ $# -lt 2 ]]; then
    echo -e "${YELLOW}Usage: nx why <package> <dependency>${NC}"
    echo "Example: nx why .#myApp openssl"
    exit 1
  fi
  nix why-depends "$@"
}

cmd_watch() {
  if [[ $# -eq 0 ]]; then
    echo -e "${YELLOW}Usage: nx watch <nix-command...>${NC}"
    echo "Runs any nix command with pretty output via nom"
    echo "Example: nx watch nix-build -A hello"
    exit 1
  fi
  echo -e "${GREEN}Running with nix-output-monitor...${NC}"
  "$@" |& nom
}

# Main dispatch
main() {
  if [[ $# -eq 0 ]]; then
    show_help
    exit 0
  fi

  local cmd="$1"
  shift

  # Handle comma syntax: nx ,package
  if [[ $cmd == ,* ]]; then
    cmd_comma "$cmd" "$@"
    exit 0
  fi

  case "$cmd" in
  # Search & Discovery
  search | s)
    cmd_search "$@"
    ;;
  locate | loc | l)
    cmd_locate "$@"
    ;;
  docs | doc | man)
    cmd_docs "$@"
    ;;

  # Build & Develop
  build | b)
    cmd_build "$@"
    ;;
  shell | sh)
    cmd_shell "$@"
    ;;
  develop | dev | d)
    cmd_develop "$@"
    ;;
  watch | w)
    cmd_watch "$@"
    ;;

  # Analysis & Inspection
  tree | t)
    cmd_tree "$@"
    ;;
  diff)
    cmd_diff "$@"
    ;;
  compare | cmp)
    cmd_compare "$@"
    ;;
  size | sz)
    cmd_size "$@"
    ;;
  why)
    cmd_why "$@"
    ;;

  # Code Quality
  lint | check | c)
    cmd_lint "$@"
    ;;
  health)
    cmd_health "$@"
    ;;

  # System Management
  os | nixos)
    cmd_os "$@"
    ;;
  home | hm)
    cmd_home "$@"
    ;;
  gc | clean)
    cmd_gc "$@"
    ;;

  # Package Creation
  url)
    cmd_url "$@"
    ;;

  # Help and version
  help | --help | -h)
    show_help
    ;;
  version | --version | -v)
    show_version
    ;;

  # Passthrough to nix
  flake | profile | registry | store | derivation | hash | key | nar | path-info | print-dev-env | realisation | bundle | copy | daemon | edit | eval | fmt | log | repl | run | upgrade-nix | doctor | show-config | why-depends)
    nix "$cmd" "$@"
    ;;

  # Unknown command - try nix
  *)
    echo -e "${YELLOW}Unknown nx command '$cmd', forwarding to nix...${NC}"
    nix "$cmd" "$@"
    ;;
  esac
}

main "$@"
