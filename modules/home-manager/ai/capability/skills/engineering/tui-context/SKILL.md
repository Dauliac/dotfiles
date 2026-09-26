---
name: tui-context
description: Open context-aware TUIs (glab ci view, k9s, stu, lazygit, ...) in herdr splits when the user starts an operation worth watching live. Applies the one-TUI-vertical-split / many-TUIs-square-grid layout rule and arms per-pane auto-close. Reach for this whenever you'd otherwise dump long polling output into chat. Does NOT trigger on one-shot printers that exit immediately — `openspec view`, `openspec list`, `openspec show`, `openspec status`, `bd ready`, `bd show`, `git log/status/diff` — these must be relayed inline via plain Bash so the user reads the output in chat. If unsure, verify the command actually stays alive (`timeout 2 <cmd>; echo exit=$?`) before spawning a pane.
---

# tui-context — spawn TUIs in the right shape, close them when done

You just did something that has a live UI story: pushed to GitLab, applied a
Kubernetes manifest, uploaded to S3, kicked off a long test suite. Instead of
tailing text in chat, put the appropriate TUI in a herdr pane, pre-scoped to
the resources in play, and let it close itself.

Uses the `herdr-tui` wrapper (see `herdr-tui --help` for full flags).

## The layout rule

**Exactly one TUI to show** → single vertical split of the current pane:

```
herdr-tui launch [--label X] [--auto-close-when '<predicate>'] -- <tui-cmd>
```

**Two or more TUIs to show at once** → new tab, then alternating splits
(right → down → right → down → …), one per TUI:

```
GRID=$(herdr-tui grid-open --label "ci+k8s")
herdr-tui grid-add "$GRID" --label ci  -- glab ci view -b main
herdr-tui grid-add "$GRID" --label k8s -- k9s --namespace api
herdr-tui grid-add "$GRID" --label s3  -- stu
```

Never open two vertical splits in the current pane — that shreds the user's
active workspace. Second TUI onwards always goes to a fresh grid tab.

## Auto-close

Every pane arms an auto-close daemon unless you pass `--keep`. Three knobs:

| Flag | Meaning |
|---|---|
| `--auto-close-on-idle SEC` | Close after SEC seconds of no engagement (focus + scroll-at-bottom). Default: 60. |
| `--auto-close-when 'SHELL'` | Poll SHELL every 5s; close when it exits 0. Use for "is the thing done?" predicates. |
| `--auto-close-timeout SEC` | Hard cap; close after SEC seconds even if the user is still watching. |
| `--keep` | Never auto-close. |

`--on-idle` and `--when` compose: whichever fires first wins. Reach for
`--when` on things with a clear "done" state (CI pipeline, deploy, migration);
fall back to `--on-idle` on things that just idle (k9s, stu, lazygit).

## When NOT to reach for this

- Quiet one-shot commands you can parse (`kubectl get pods -o json`) — use Bash.
- Text output you need to feed into your next reasoning step — use `herdr-run`
  (captures stdout, single split, same auto-close pattern).
- The user opted out of visible panes in this session.
- **One-shot printers masquerading as TUIs** — commands whose name sounds
  interactive (`view`, `dashboard`, `status`, `report`, `summary`, `show`)
  but that print once and exit. The pane dies the instant the process
  exits; the user sees nothing. Relay the output inline in chat instead
  (plain Bash), so the human reads it in the conversation they're already
  looking at. Known offenders on this machine:
  - `openspec view` — prints the dashboard and exits 0. Same for
    `openspec list`, `openspec show`, `openspec status`.
  - `bd ready`, `bd show <id>`, `bd list` — one-shot readouts.
  - `git log --oneline -n <small>`, `git status`, `git diff` (fits screen).
  - Anything you'd expect to see rendered as a Markdown block.

  Rule of thumb: if the command exits within ~1 second in a plain shell
  with no `--watch` / `--follow` / `-f` / REPL flag, it is NOT a TUI.
  Verify before spawning if unsure: `timeout 2 <cmd>; echo exit=$?`.
  If `exit=0` and the process is done, it's a printer — inline it.

## Companion skills

- **ci-watch** — GitLab pipelines via `glab ci view`.
- **k8s-watch** — kubernetes context/namespace/resource-scoped `k9s`.
- **s3-watch** — S3 buckets via `stu`.
- **herdr-run** — non-TUI commands you want the user to *see* run.
- **herdr-layout** — the primitives `herdr-tui` composes: pane split
  vs. new tab decisions map onto `herdr pane split` / `herdr tab
  create`. Reach for `herdr-layout` when you need shape control
  beyond the one-vs-many rule.
- **herdr-find** — locate an existing TUI pane before spawning a
  duplicate (e.g. a `k9s` already scoped to the right cluster).

When multiple companions apply to the same session (e.g. a deploy that hits
both GitLab CI and k8s), invoke each with `grid-add` against a single
`grid-open` so they share one grid tab.
