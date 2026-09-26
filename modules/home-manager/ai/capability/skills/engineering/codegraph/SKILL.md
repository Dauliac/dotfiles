---
name: codegraph
description: Semantic code intelligence — locate symbols, follow callers/callees, measure blast radius, and pull relevant source in one shot, on any repository. Trigger BEFORE grep/find/ripgrep for any question of the form "where is X defined", "who calls X", "who does X call", "what would break if I change X", "which tests cover X", "what's in this file", or "explain this area of the codebase". Also trigger on entering a fresh clone that has no `.codegraph/` yet ("index this repo", "set up code intelligence here", "onboard this repo") — offer to run `codegraph init -y` so the graph exists for the current and every future session. Prefer the `codegraph_explore` / `codegraph_node` / `codegraph_callers` / `codegraph_callees` / `codegraph_impact` / `codegraph_affected` MCP tools when available; fall back to the `codegraph` CLI otherwise.
---

# codegraph — semantic code intelligence

`codegraph` builds a per-repo symbol + call graph and answers "where /
who / what if" questions with the actual source, cross-file call
paths, and dynamic-dispatch hops grep can't follow. Reach for it
**before** `grep`/`rg`/`find` on any code-navigation task. Grep sees
strings; codegraph sees definitions, references, and reachability.

## Before every code-navigation task

1. **Check for an index.** If `.codegraph/` exists at the repo root,
   the graph is live — use it. If not, offer to bootstrap:

   ```bash
   test -d .codegraph && echo "indexed" || codegraph init -y
   ```

   `init` is safe on any repo — it writes only to `.codegraph/`. It
   is idempotent; re-run turns into a `sync`.

2. **After a `git pull`**, refresh incrementally:

   ```bash
   codegraph sync
   ```

   Fast — only touches files changed since the last index. Do this
   automatically after any pull / branch switch that moves code.

3. **Prefer MCP over CLI when the MCP server is wired** (it is on
   this machine — see `modules/home-manager/ai/capability/mcp.nix`).
   MCP tools return structured output; the CLI mirrors them for
   scripts and shells:

   | Task | MCP tool | CLI mirror |
   | --- | --- | --- |
   | "Understand this area / question" | `codegraph_explore` | `codegraph explore "<query…>"` |
   | "One symbol's source + caller/callee trail" | `codegraph_node` | `codegraph node <symbol>` |
   | "Who calls X?" | `codegraph_callers` | `codegraph callers <symbol>` |
   | "Who does X call?" | `codegraph_callees` | `codegraph callees <symbol>` |
   | "What breaks if I change X?" | `codegraph_impact` | `codegraph impact <symbol>` |
   | "Which tests are affected by these files?" | `codegraph_affected` | `codegraph affected <files…>` |

## When to reach for it (vs grep / rg / Read)

| Question | Right tool |
| --- | --- |
| "Where is `AuthService` defined?" | `codegraph_node AuthService` (or `codegraph node`) — returns source + line numbers |
| "Who calls `AuthService.login`?" | `codegraph_callers AuthService.login` — follows dispatch, not just text |
| "Explain the auth flow" | `codegraph_explore "auth flow login session"` — pulls all relevant symbols + call paths |
| "What would break if I rename `session_key`?" | `codegraph_impact session_key` |
| "Read `src/auth/service.ts` with line numbers + who depends on it" | `codegraph node -f src/auth/service.ts` (file mode) |
| "Find every literal string `"TODO"`" | `rg 'TODO'` — codegraph is not a substring search |
| "Find every occurrence of a shell env var name" | `rg` — non-code, out of graph |
| "Read one small file front-to-back" | `Read` — cheaper than round-tripping the graph |

**Rule of thumb**: if the answer depends on what a symbol *means*
(definition, call graph, blast radius), reach for codegraph. If it
depends on what a string *looks like* (literals, comments, non-code
files), reach for `rg`.

## Recipes

**"Where does this behavior live?"** — one call, source + trail:

```bash
codegraph explore "checkout webhook idempotency"
```

Returns the relevant symbols' verbatim source and the call paths
between them, ready to reason on.

**"Who touches this symbol?"** — before renaming or removing:

```bash
codegraph callers UserRepository.findByEmail
codegraph impact UserRepository.findByEmail
```

`callers` is a one-hop list; `impact` walks transitively and includes
tests / entry points that would need re-verification.

**"Which tests should I run for these changed files?"**:

```bash
codegraph affected src/auth/service.ts src/auth/session.ts
```

Feed the output straight into the test runner's file filter.

**"Read this file with structure"**:

```bash
codegraph node -f src/auth/service.ts             # source + symbol map + dependents
codegraph node -f src/auth/service.ts --symbols-only  # just the map
codegraph node -f src/auth/service.ts --offset=120 --limit=40
```

**"What files does the index know about?"** — sanity check after a
`sync` or before a big query:

```bash
codegraph files
codegraph status
```

## Lifecycle

| Situation | Command |
| --- | --- |
| First time in a repo | `codegraph init -y` (idempotent, writes only `.codegraph/`) |
| After `git pull` / branch switch | `codegraph sync` |
| Something looks stale / dispatch missed | `codegraph index` (full rebuild) |
| Lock file left over from a crashed run | `codegraph unlock` |
| Retire the graph from a repo | `codegraph uninit` |
| Wire MCP into a fresh agent install | `codegraph install -y --init` (installs + first index) |

`.codegraph/` should be gitignored per-repo; the index is machine-
local. Add one line to the repo's `.gitignore` when you `init`:

```bash
grep -q '^\.codegraph/' .gitignore 2>/dev/null || echo '.codegraph/' >> .gitignore
```

## Gotchas

- **`.codegraph/` gates everything.** If it's missing and you run a
  query, you get nothing useful. Always check → offer `init` if
  absent. Do not silently fall back to grep — the user asked for
  codegraph on every repo.
- **Rename / move → `sync` first.** Stale symbol positions produce
  wrong `node` / `callers` output. `sync` is cheap; run it.
- **Dynamic dispatch has limits.** Interface / trait / duck-typed
  calls resolve to the best static candidate. If `callers` returns
  suspiciously few hits on a method behind an interface, cross-check
  with `rg 'method_name\('` and reconcile.
- **Not for non-code text.** Config files, docs, YAML — grep those.
  Codegraph indexes code symbols.
- **Long queries in `explore` help.** `codegraph explore "auth"` is
  noisy; `codegraph explore "auth login session cookie renewal"`
  narrows the graph walk. Verbose = better here.
- **`--max-files` on `explore`** to cap source volume when a query
  touches a huge cluster.
- **Never `rm -rf .codegraph/` casually** — a `sync` after a merge is
  faster than rebuilding from scratch on a large repo. Use `unlock`
  for stale locks, `uninit` for retirement.

## Composes with

- **jira-explore**: on landing in the repo the ticket points at, run
  `test -d .codegraph || codegraph init -y`, then use
  `codegraph_explore` for "where does this bug live" rather than
  hand-rolled greps. Feeds `proof.md` with real symbol + call paths.
- **jira-fix**: `codegraph_impact <symbol>` before designing the fix
  — mandatory input to the blast-radius section of `fix.md`.
  `codegraph_affected <changed-files>` picks the test set.
- **jira-ticket**: mention codegraph state in the setup hand-off
  ("indexed at N files, sync current as of `git rev-parse HEAD`").
- **ghq**: pair with `ghq get -p` — on a fresh clone, add `codegraph
  init -y` right after to make the repo queryable from the first
  session.
- **hunk**: run `codegraph impact` before opening `hunk diff` so the
  review pane can be scoped to affected areas.
- **beads**: note the codegraph findings (symbol names, call paths)
  in the bead so future sessions can reproduce without re-querying.
- **repo-tasks**: if the same `codegraph sync` / `codegraph init`
  invocation belongs to a repo's normal lifecycle, promote it into
  the repo's task runner.
- **herdr-run**: for a full `codegraph index` on a large repo (long
  running), open in a herdr split rather than blocking the sync call.
