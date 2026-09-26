---
name: scratch-scripts
description: Reuse existing scratch helper scripts under ~/.cache/claude/scratch/ before writing a new one-off shell/awk/python helper. Use when you're about to write a repeatable one-liner (log parsing, format conversion, batch rename, data extraction, CI probe, JSON reshape). The SessionStart hook `scratch-index.sh` injects the current library into context — reach for a listed script first, promote a fresh one when the pattern is worth keeping.
---

# scratch-scripts — reuse-first helpers for repeat one-offs

`~/.cache/claude/scratch/` is a flat, cross-project library of reusable
helper scripts. It exists because the same shell dance keeps getting
rewritten across sessions and wastes tokens. Reach for what's already
there before writing new.

## The three moves

### 1. Reuse

Before writing any helper > ~5 lines, check the SessionStart-injected
library index (or `ls ~/.cache/claude/scratch/`). If a listed script
solves your problem — even 70% — invoke it and move on.

```bash
~/.cache/claude/scratch/parse_gary_logs.sh /path/to/log
```

### 2. Promote

If you're about to write the same shell dance a **second** time in a
session (or you'd bet you'll want it again next week), promote it:

```bash
cat > ~/.cache/claude/scratch/<verb>_<noun>.sh <<'EOF'
#!/usr/bin/env bash
# One-line description of what this does and when to use it.
set -euo pipefail
# ... logic ...
EOF
chmod +x ~/.cache/claude/scratch/<verb>_<noun>.sh
```

Rules:

- **First comment line after the shebang is the docstring** — that's
  what the index hook shows to future sessions. Make it search-friendly.
- **Naming**: `<verb>_<noun>.sh` — `parse_bd_ready.sh`, `strip_ansi.sh`,
  `count_open_prs.sh`. Verbs help future-you recall.
- **Self-contained**: no `source ../lib/*.sh` — the scratch dir is flat.
- **Fail fast**: `set -euo pipefail`, quote variables, exit non-zero on
  bad input.
- **Idempotent when reasonable**: reading twice should give the same
  answer; writes should tolerate re-runs.

### 3. Update / retire

- **Update** when the script needs a new flag or a bug fix. Preserve the
  docstring semantics or update it in the same edit.
- **Retire** by `rm` when the script no longer applies (tool removed,
  workflow changed, or `atime` is > 30 days old and you can't recall
  what it does). Don't leave dead scripts confusing the next session.

## When NOT to promote

- Single-use commands you'll never repeat (`grep foo one_file.log`) —
  just run the pipeline.
- Trivial wrappers around one CLI call (`herdr pane current | jq
  .result.pane.pane_id`) — no clearer as a script than as a shell line.
- Anything with secrets baked in — scratch is world-readable.
- Anything project-specific — put it in that project's `.claude/scratch/`
  (if configured) or a slash command instead.

## Discovery

The `~/.claude/hooks/scratch-index.sh` script (shipped by the same nix
module as this skill) lists the library on session start when wired as a
Claude Code SessionStart hook. If the index isn't showing up in a new
session, check:

```bash
ls ~/.cache/claude/scratch/                            # dir exists?
jq '.hooks.SessionStart' ~/.claude/settings.json       # hook wired?
bash ~/.claude/hooks/scratch-index.sh                  # manual run
```

## Composes with

- **herdr-run**: run promoted scripts visibly in a split pane when the
  user should watch the output.
- **beads**: for scripts whose provenance / rationale matters across
  machines, `bd remember "scratch/foo.sh solves X — original context: …"`
  — the scripts live locally per host, but their existence + reason sync.
- **skill-creator** (if installed): when a scratch script gets flags,
  branches, and worked examples, it's outgrown scratch — promote it to a
  real skill via `/skill-creator`.
