---
name: jira-merge
description: Merge the MR + (if the repo is tag-managed) cut a release tag. Verifies `glab-mr-ready` is green first (pipeline success, approvals met, no conflicts, no draft prefix), then `glab mr merge` with the correct flags (squash / remove-source-branch / when-pipeline-succeeds per project convention), then detects tag-management via `.releaserc*` / `.goreleaser.*` / recent semver tags — if tag-managed, cut the next tag via `glab release create` OR trigger the release job; otherwise skip-close. Trigger on "merge the MR", "merge !123", "cut the release", "tag and release", "ready to ship", "un-draft and merge". The `phase:merge` + `phase:tag` step of the support-ticket bead DAG.
---

# jira-merge — merge + (conditional) tag

**DOR/DOD gates:** see `jira-ticket/references/dor-dod.md` §
`phase:merge` and `phase:tag`. Refuse to merge unless the DOR block
holds (readiness green, review closed, DOR re-checked *now* — state
drifts between review and merge). On close, verify DOD: `state ==
"merged"`, `merge_commit_sha` non-null, `find_mr_urls $KEY` still
returns the MR URL (proves the Jira ↔ MR link survived the merge).

Owns the "ship it" step. Refuses to merge until `glab-mr-ready` is
fully green. After merge, detects whether the repo is tag-managed
and either creates the next release tag or skip-closes the tag bead.

## When to reach for it

- `phase:review` bead closed (approvals green, threads resolved).
- `phase:ci-green` bead closed (pipeline success).
- Operator says "merge it", "ship it", "cut the release".

Do NOT reach for it while the MR is still Draft — un-draft is a
separate action (`glab mr update $IID --ready`); this skill assumes
the operator has signalled readiness.

## Prerequisites

- Read `glab-mr-ready` — the mandatory readiness gate this skill
  re-runs before merging.
- MR IID + repo.

## Step 1 — Re-run the readiness gate

Do NOT trust a stale readiness report. State can drift between
"reviewer approved 20 min ago" and "now" — someone pushed a fixup
that started a fresh pipeline, or a rebase invalidated approvals.

```bash
# Delegate to glab-mr-ready — it emits the structured report and
# exits non-zero on any red row. Refuse to merge on non-zero.
glab-mr-ready check "$IID" --repo "$REPO" || {
  echo "Refusing to merge — readiness gate red. See report above." >&2
  exit 1
}
```

## Step 2 — Merge the MR

`glab mr merge` flag choice depends on the repo's convention:

| Flag | When |
| --- | --- |
| `--squash` | Repos that prefer one commit per MR (default at ManoMano for most services) |
| `--rebase` | Repos preserving individual commits with a linear history |
| `--remove-source-branch` | Almost always — matches `--draft` creation flow |
| `--when-pipeline-succeeds` (`-w`) | If the operator wants "auto-merge once pipeline goes green" instead of waiting live |
| `--yes` | Skip glab's confirmation prompt (safe once the readiness gate has just fired) |

```bash
glab mr merge "$IID" --repo "$REPO" \
  --squash --remove-source-branch --yes
```

Alternative: **auto-merge-when-pipeline-succeeds** (fires now, GitLab
polls, merges when green):

```bash
glab mr merge "$IID" --repo "$REPO" \
  --squash --remove-source-branch --when-pipeline-succeeds --yes
```

Prefer `--when-pipeline-succeeds` for repos where the merge pipeline
takes >5 min — frees the operator instead of blocking the loop.

Verify the merge landed:

```bash
glab mr view "$IID" --repo "$REPO" --output json \
  | jq '{state, merged_by:.merge_user.username, merged_at, merge_commit_sha}'
```

Expect `state: "merged"`. If `state: "opened"` still, the merge
failed (see `merge_error` field for reason — common: conflicts
appeared during rebase, protected branch rule, missing approval).

## Step 3 — Tag-management detection

Not every repo cuts its own tags — many trigger a release job on
merge that tags itself, or don't tag at all (Spinak IaC repos).
Detection heuristic (any TRUE → assume tag-managed by human):

```bash
tag_managed=false
[ -e .releaserc ] || [ -e .releaserc.yml ] || [ -e .releaserc.json ]  && tag_managed=true
[ -e .goreleaser.yaml ] || [ -e .goreleaser.yml ]                     && tag_managed=true
grep -qE '^\s*release:' .gitlab-ci.yml 2>/dev/null                    && tag_managed=true
# Recent semver tag on the default branch — strong signal
git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -1 \
  | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+$'                              && tag_managed=true
```

If ALL false → this repo probably auto-tags via CI OR doesn't tag.
Skip-close the `phase:tag` bead with a note:

```bash
bd close "$tag_bead" && bd note "$tag_bead" \
  "Skipped — no tag-management signal in repo (no .releaserc / \
.goreleaser / release: CI job / semver tag history)."
```

## Step 4 — Cut the tag (if managed)

Three common shapes:

**A. Semantic-release (`.releaserc.*`)** — release is a CI job on
merge to master; no manual tag needed. Skip-close with a note
pointing at the release job:

```bash
bd note "$tag_bead" "semantic-release will tag from the merge job. \
Watch: glab ci status -b master --repo $REPO"
bd close "$tag_bead"
```

**B. GoReleaser + manual tag push**:

```bash
next=$(git tag --sort=-v:refname | head -1 | awk -F. '{
  ver=$0; sub(/^v/,"",ver);
  split(ver,a,".");
  print "v" a[1] "." a[2] "." (a[3]+1)   # bump patch
}')
# Confirm with operator before firing — tag pushes are hard to undo.
echo "About to tag: $next. Confirm? [y/N]"
read -r ok < /dev/tty; [ "$ok" = "y" ] || exit 1

git tag -a "$next" -m "release $next" -s
git push origin "$next"
```

**C. GitLab release via glab (creates the release object + tag)**:

```bash
glab release create "$next" --repo "$REPO" \
  --name "$next" \
  --notes-file CHANGELOG.md   # or --notes "one-liner"
```

## Step 5 — Notify the Jira ticket

Post an internal status ping via `twg jira workitem comment create --issue-id "$KEY" --body "..." --body-format markdown`:

```text
Merged !$IID (commit <short-sha>). Release: $next (or "auto-release
via CI"). Deploy pipeline: <URL>. Will verify per env.
```

Do NOT transition the Jira ticket to Done yet — deploy + verify are
still ahead. `jira-answer` handles Done after `verify-prod` closes.

## Anti-patterns

- **Merging without re-running the readiness gate** — state drifts;
  a stale check misses a fresh fixup commit or a revoked approval.
- **Hard-coding the merge strategy** — check the project's
  `merge_method` setting (`glab api projects/$PROJ_ID | jq
  .merge_method`) — some are `ff`-only.
- **Auto-tagging a repo that auto-tags** — creates two tags for
  one release, breaks changelog tools. Detect first.
- **Merging with `--no-verify` or `--force-push` fallbacks** — never,
  unless the operator explicitly asks and knows why.
- **Transitioning Jira to Done immediately after merge** — the
  fix isn't verified in prod yet. Done belongs after
  `phase:verify env:prod` closes.

## Composes with

- **glab-mr-ready** — mandatory pre-merge gate.
- **twg-jira** — `twg jira workitem comment create` for the post-merge status ping on the Jira ticket.
- **jira-deploy** — the next phase; consumes the merge commit sha.
- **jira-answer** — the phase that transitions Done, MUCH later.
- **beads-flow** — dispatches this skill on `phase:merge` and
  `phase:tag` beads.
- **ci-watch** — if `--when-pipeline-succeeds` is in play, open the
  pipeline live so the operator sees the auto-merge fire.
