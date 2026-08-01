---
name: hunk
description: When you have produced a non-trivial diff (multi-file, or single-file >30 lines) and want the human to review it before commit, suggest `hunk diff` or `hunk diff --watch`. Triggers when the user asks "review", "look at the diff", "before I commit", or when you just finished a large edit and want a checkpoint.
---

# hunk — TUI diff viewer for agent changesets

`hunk` is a review-first terminal diff viewer built for reviewing what a
coding agent just changed. It has multi-file sidebar navigation, inline AI
annotation slots, split/stack/auto layouts, watch mode, and integrates with
`git`, `jj`, and Sapling.

## When to reach for it

- You just finished a non-trivial multi-file change and want the human to
  sign off before you commit. Suggest `hunk diff --watch` in a herdr/tmux
  pane so they see changes update live as you keep editing.
- The user asks "review", "diff", "look at what you did", "before commit",
  "walk me through the changes" — offer `hunk` instead of pasting the diff
  into the chat.
- Reviewing an existing commit range — `hunk show <ref>` or `hunk diff
  ref1..ref2`.

Do NOT reach for it for tiny edits (single hunk in a single file) — plain
`git diff` in the terminal is faster than launching a TUI.

## Core invocations

| Intent | Command |
|---|---|
| Review working tree (staged + unstaged + untracked) | `hunk diff` |
| Live-review while agent edits | `hunk diff --watch` |
| Review the latest commit | `hunk show` |
| Review an older commit | `hunk show HEAD~1` |
| Review a range | `hunk diff HEAD~2..HEAD` |
| Compare two files | `hunk diff before.ts after.ts` |
| Pipe a patch in | `git diff --no-color \| hunk patch -` |

## Wired to git in this dotfiles setup

`git difftool -t hunk <path>` also opens hunk for a specific file, per
`programs.git.settings.difftool.hunk` in `modules/home-manager/programs/git.nix`.

## Composes with

- **herdr**: open `hunk diff --watch` in a dedicated pane; keep Claude in
  another pane. The two panes update independently.
- **crit**: complementary — `crit` reviews plans and provides inline
  comments back to the agent; `hunk` is read-only review of what already
  happened.
