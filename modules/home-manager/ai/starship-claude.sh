# starship-claude - Use Starship for your Claude Code status line
# Based on https://github.com/martinemde/starship-claude (MIT License, Martin Emde)

# Configuration: context window progress thresholds
PROGRESS_COMPACT=80
PROGRESS_YELLOW=40
PROGRESS_RED=60

# NerdFont model icons
HAIKU_NERD=" "
SONNET_NERD="󰚩 "
OPUS_NERD="󱚦 "

# Parse command line options
show_progress=1
starship_config=""
while [ $# -gt 0 ]; do
  case "$1" in
  --no-progress)
    show_progress=0
    shift
    ;;
  --config)
    if [ $# -lt 2 ]; then
      echo "Error: --config requires a path argument" >&2
      exit 1
    fi
    starship_config="$2"
    shift 2
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

payload="$(cat || true)"

if [ -n "$payload" ]; then
  jq_output="$(printf '%s' "$payload" | jq -r '
    [
      (.transcript_path // ""),
      (.cwd // ""),
      (.workspace.current_dir // ""),
      (.workspace.project_dir // ""),
      (.version // ""),
      (.output_style.name // ""),
      (.model.id // ""),
      (.model.display_name // ""),
      (.cost.total_cost_usd // ""),
      (.cost.total_duration_ms // ""),
      (.cost.total_api_duration_ms // ""),
      (.cost.total_lines_added // ""),
      (.cost.total_lines_removed // ""),
      (.context_window.total_input_tokens // ""),
      (.context_window.total_output_tokens // ""),
      (if .exceeds_200k_tokens == null then "" else .exceeds_200k_tokens | tostring end),
      (.session_id // ""),
      (.context_window.context_window_size // ""),
      (if .context_window.current_usage == null then "" else (.context_window.current_usage.input_tokens // 0) end),
      (if .context_window.current_usage == null then "" else (.context_window.current_usage.output_tokens // 0) end),
      (if .context_window.current_usage == null then "" else (.context_window.current_usage.cache_creation_input_tokens // 0) end),
      (if .context_window.current_usage == null then "" else (.context_window.current_usage.cache_read_input_tokens // 0) end),
      (.model.display_name // .model.id // ""),
      (.workspace.current_dir // .workspace.project_dir // .cwd // ""),
      (.rate_limits.five_hour.used_percentage // ""),
      (.rate_limits.seven_day.used_percentage // ""),
      (.rate_limits.five_hour.resets_at // ""),
      (.rate_limits.seven_day.resets_at // "")
    ] | .[]
  ')"

  values=("" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "")

  if [ -n "$jq_output" ]; then
    if command -v mapfile >/dev/null 2>&1; then
      mapfile -t values <<<"$jq_output"
    else
      i=0
      while IFS= read -r line; do
        values[i]="$line"
        i=$((i + 1))
      done <<<"$jq_output"
    fi
  fi

  export CLAUDE_TRANSCRIPT_PATH="${values[0]:-}"
  export CLAUDE_CWD="${values[1]:-}"
  export CLAUDE_WORKSPACE_CURRENT_DIR="${values[2]:-}"
  export CLAUDE_WORKSPACE_PROJECT_DIR="${values[3]:-}"
  export CLAUDE_VERSION="${values[4]:-}"
  export CLAUDE_OUTPUT_STYLE="${values[5]:-}"
  export CLAUDE_MODEL_ID="${values[6]:-}"
  export CLAUDE_MODEL_DISPLAY_NAME="${values[7]:-}"
  export CLAUDE_COST_RAW="${values[8]:-}"
  export CLAUDE_TOTAL_DURATION_MS="${values[9]:-}"
  export CLAUDE_API_DURATION_MS="${values[10]:-}"
  export CLAUDE_LINES_ADDED="${values[11]:-}"
  export CLAUDE_LINES_REMOVED="${values[12]:-}"
  export CLAUDE_TOTAL_INPUT_TOKENS="${values[13]:-}"
  export CLAUDE_TOTAL_OUTPUT_TOKENS="${values[14]:-}"
  export CLAUDE_EXCEEDS_200K="${values[15]:-}"
  export CLAUDE_SESSION_ID="${values[16]:-}"
  export CLAUDE_CONTEXT_SIZE="${values[17]:-}"
  export CLAUDE_INPUT_TOKENS="${values[18]:-}"
  export CLAUDE_OUTPUT_TOKENS="${values[19]:-}"
  export CLAUDE_CACHE_CREATION="${values[20]:-}"
  export CLAUDE_CACHE_READ="${values[21]:-}"
  export CLAUDE_RATE_5H_RAW="${values[24]:-}"
  export CLAUDE_RATE_7D_RAW="${values[25]:-}"
  export CLAUDE_RATE_5H_RESETS="${values[26]:-}"
  export CLAUDE_RATE_7D_RESETS="${values[27]:-}"

  raw_model="${values[22]:-}"
  dir="${values[23]:-}"

  if [ -n "$dir" ] && [ -d "$dir" ]; then
    cd "$dir" || true
  fi

  # Short model name with nerd font icon
  if [ -n "$raw_model" ]; then
    if [[ ${BASH_VERSINFO[0]:-0} -ge 4 ]]; then
      lower_model="${raw_model,,}"
    else
      lower_model="$(printf '%s' "$raw_model" | tr '[:upper:]' '[:lower:]')"
    fi

    case "$lower_model" in
    *haiku*) model_nerd="$HAIKU_NERD" ;;
    *sonnet*) model_nerd="$SONNET_NERD" ;;
    *opus*) model_nerd="$OPUS_NERD" ;;
    *) model_nerd="$SONNET_NERD" ;;
    esac

    export CLAUDE_MODEL="$lower_model"
    export CLAUDE_MODEL_NERD="$model_nerd$lower_model"
  fi

  # Cost formatting
  raw_cost="${values[8]:-}"
  if [ -n "$raw_cost" ]; then
    export CLAUDE_COST
    CLAUDE_COST="$(printf '$%.2f' "$raw_cost")"
  fi

  # Session summary from transcript
  export CLAUDE_SUMMARY=""
  transcript_path="${values[0]:-}"
  if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    summary="$(jq -rs '[.[] | select(.type == "summary")] | last | .summary // empty' "$transcript_path")"
    if [ -n "$summary" ]; then
      summary="${summary//$'\n'/ }"
      summary="${summary//  / }"
      summary="${summary# }"
      summary="${summary% }"
      export CLAUDE_SUMMARY="$summary"
    fi
  fi

  # Context window usage percentage
  context_size="${values[17]:-}"
  input_tokens="${values[18]:-}"
  cache_creation="${values[20]:-}"
  cache_read="${values[21]:-}"

  if [ -n "$context_size" ] && [ "$context_size" != "null" ] && [ -n "$input_tokens" ]; then
    current_tokens=$((${input_tokens:-0} + ${cache_creation:-0} + ${cache_read:-0}))
    export CLAUDE_CURRENT_TOKENS="$current_tokens"

    if [ "$current_tokens" -gt 0 ]; then
      percent_used=$((current_tokens * 100 / context_size))
      export CLAUDE_PERCENT_RAW="$percent_used"
      export CLAUDE_CONTEXT
      CLAUDE_CONTEXT="$(printf '%3s' "${percent_used}%")"
    else
      export CLAUDE_CONTEXT="~~%"
    fi
  else
    export CLAUDE_CONTEXT="~~%"
  fi

  # Rate limit formatting
  _fmt_remaining() {
    local resets_at="$1"
    [ -z "$resets_at" ] || [ "$resets_at" = "null" ] && return
    local now remaining days hours minutes
    now=$(date +%s)
    remaining=$((resets_at - now))
    [ "$remaining" -le 0 ] && return
    days=$((remaining / 86400))
    hours=$(((remaining % 86400) / 3600))
    minutes=$(((remaining % 3600) / 60))
    if [ "$days" -gt 0 ]; then
      printf '%dd %dh' "$days" "$hours"
    else
      printf '%dh %dm' "$hours" "$minutes"
    fi
  }

  rate_5h_raw="${values[24]:-}"
  rate_7d_raw="${values[25]:-}"
  rate_5h_resets="${values[26]:-}"
  rate_7d_resets="${values[27]:-}"

  if [ -n "$rate_5h_raw" ] && [ "$rate_5h_raw" != "null" ]; then
    _remaining=$(_fmt_remaining "$rate_5h_resets")
    if [ -n "$_remaining" ]; then
      export CLAUDE_RATE_5H="${rate_5h_raw%.*}% ($_remaining)"
    else
      export CLAUDE_RATE_5H="${rate_5h_raw%.*}%"
    fi
  else
    export CLAUDE_RATE_5H=""
  fi

  if [ -n "$rate_7d_raw" ] && [ "$rate_7d_raw" != "null" ]; then
    _remaining=$(_fmt_remaining "$rate_7d_resets")
    if [ -n "$_remaining" ]; then
      export CLAUDE_RATE_7D="${rate_7d_raw%.*}% ($_remaining)"
    else
      export CLAUDE_RATE_7D="${rate_7d_raw%.*}%"
    fi
  else
    export CLAUDE_RATE_7D=""
  fi
fi

# Determine Starship config path
if [ -z "$starship_config" ]; then
  starship_config="$HOME/.claude/starship.toml"
fi

# Detect real terminal width via parent process TTY
term_width=""
parent_tty="$(ps -o tty= -p "$(ps -o ppid= -p $$)" 2>/dev/null | tr -d ' ')" || true
if [ -n "$parent_tty" ] && [ "$parent_tty" != "??" ] && [ "$parent_tty" != "?" ]; then
  w="$(stty size <"/dev/$parent_tty" 2>/dev/null | awk '{print $2}')" || true
  if [ -n "$w" ] && [ "$w" -gt 0 ] 2>/dev/null; then
    term_width=$((w - 6))
  fi
fi

# Build starship prompt arguments
starship_args=("prompt")
if [ -n "$term_width" ]; then
  starship_args+=("-w" "$term_width")
fi

STARSHIP_CONFIG="$starship_config" \
  STARSHIP_SHELL=sh \
  starship "${starship_args[@]}"

# Terminal progress bar (OSC 9;4)
if [ "$show_progress" = "1" ]; then
  if [ -n "${percent_used:-}" ]; then
    if [ "$percent_used" -ge "$PROGRESS_COMPACT" ]; then
      progress_percent=100
    else
      progress_percent=$((percent_used * 100 / PROGRESS_COMPACT))
    fi

    if [ "$percent_used" -ge "$PROGRESS_RED" ]; then
      progress_state=2
    elif [ "$percent_used" -ge "$PROGRESS_YELLOW" ]; then
      progress_state=4
    else
      progress_state=1
    fi
    printf '\033]9;4;%d;%d\a' "$progress_state" "$progress_percent" >/dev/tty 2>/dev/null || true
  fi
fi
