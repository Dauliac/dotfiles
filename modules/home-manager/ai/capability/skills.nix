let
  skillsDir = ./skills;

  # Engineering: dev workflow + generic CLI tool wrappers.
  engineering = [
    # async-wait — Claude-side background waits (Bash bg / Monitor /
    # ScheduleWakeup / CronCreate) with bead-anchored wake-back.
    # Complements the foreground TUI watchers (ci-watch, k8s-watch, s3-watch).
    "async-wait"
    "aws"
    "beads"
    # beads-* — agnostic execution patterns on top of the beads CLI.
    "beads-decompose"
    "beads-flow"
    "ci-watch"
    "codegraph"
    "commit-rationale"
    # concurrent-worktrees — decision-trigger skill: split a second
    # track of work into its own git worktree via `try worktree` when
    # a parallel task would otherwise land in the same cwd as an
    # in-flight change (uncommitted diffs, running dev server, or a
    # fleet of parallel subagents each editing code). Composes with
    # `try`, `ghq`, `herdr-layout`, `beads`, `hunk`, `jira-ticket`.
    "concurrent-worktrees"
    # glab-ci-manual-triage — enumerate manual gates blocking a
    # pipeline; AskUserQuestion per gate (FIRE / SKIP / DEFER);
    # fire via glab api POST /jobs/:jid/play. Invoked by
    # glab-push-flow and async-wait §4a on the fail-fast poller's
    # exit code 5 (MANUAL_BLOCKED).
    "glab-ci-manual-triage"
    # confluenceai — Confluence Cloud REST v2 cookbook (parallel to jiraai;
    # shares the Atlassian API token). confluence-auto-read is the always-on
    # trigger that fires whenever a Confluence URL / bare reference / vague
    # "the runbook"-style mention appears in incoming text.
    "confluenceai"
    "confluence-auto-read"
    "dust"
    "explicit-cluster-context"
    "ezsre"
    "ghq"
    "glab"
    # glab-mr-* — MR-workflow skills that address specific glab-CLI
    # footguns (silent no-op on bad reviewer usernames, replace-by-
    # default semantics, double Draft: prefix, empty assignee), plus
    # the automerge atom composed by glab-push-flow.
    "glab-mr-assign"
    # glab-mr-automerge — atomic MWPS arm on an MR IID with draft
    # refusal, project-strategy detection, and post-arm verification.
    # Mandatory next step for glab-mr-open; step 2 of glab-push-flow.
    "glab-mr-automerge"
    "glab-mr-open"
    "glab-mr-ready"
    "glab-mr-title"
    # glab-push-flow — post-push lifecycle orchestrator. After any
    # git push / mr create / ci retry: detect MR → automerge →
    # ci-watch split → async-wait fail-fast → on MANUAL_BLOCKED
    # (exit 5) → manual-triage → re-arm. Composes atomic skills;
    # does NOT re-implement them.
    "glab-push-flow"
    # herdr-* — terminal workspace family:
    #   herdr         — top-level CLI reference + gotchas
    #   herdr-layout  — shape the workspace (split, tab, workspace, worktree CRUD)
    #   herdr-find    — read-only discovery / search across the socket API
    #   herdr-run     — split + run a command + capture stdout
    "herdr"
    "herdr-find"
    "herdr-layout"
    "herdr-run"
    "hunk"
    # jiraai-* — Jira workflow skills. The generic CRUD skills
    # (jiraai-comment/create/edit/list) were dropped in favor of
    # `twg jira workitem <comment create|create|update|query>`; the
    # jiraai cookbook now covers only the twg-can't-do-this residue
    # (find_mr_urls 5-source union, PLAT capability enum, hierarchy
    # traps, sops break-glass). Distinct from the productivity/support
    # jira-* family (jira-ticket → jira-explore → jira-fix → jira-answer).
    "jiraai"
    "jiraai-commit-check"
    # jiraai-freshness-check  -  atomic pre-post safety gate. Snapshot
    # the ticket at draft time; diff at post time; refuse to write
    # (comment / transition / update) when a new non-me comment
    # landed or the status moved. Motivating incident: PLAT-4095
    # 2026-09 (a teammate's comment invalidated the draft mid-flight
    # and the agent posted the stale reply anyway). Called by
    # jira-answer, jira-fix, jira-review, jira-merge, jiraai-group.
    # jira-ticket-statewright-toggle — routing addendum. When an operator
    # invocation of the jira-ticket pipeline carries --via-statewright (or
    # after cutover: any bare invocation without --legacy), delegate to
    # `/sw:ticket <TICKET-ID>` and skip the hardcoded pipeline. Introduced
    # by the statewright-workflow-layer OpenSpec change; complements the
    # 3-line pointer in jira-ticket/SKILL.md.
    "jira-ticket-statewright-toggle"
    "jiraai-group"
    "jiraai-link"
    "jiraai-mr"
    "jiraai-review"
    "k8s-watch"
    "kubectl"
    "mg-watch"
    "mise-deps"
    "mise-quality-gates"
    "mise-tasks"
    # pre-commit-lint — cross-runner (hk / mise / just / Task / Make)
    # visible pre-commit gates via herdr-run. Supersedes
    # mise-quality-gates when non-mise runners are also present;
    # composes with it otherwise.
    "pre-commit-lint"
    "pup"
    "repo-tasks"
    "s3-watch"
    "scratch-scripts"
    # slack — Slack's official platform CLI wrapped in atomic sub-skills
    # scoped to the "read + send messages via the Web API" use case
    # (chat.*, conversations.*, users.*, search.*, reactions.*, files.*).
    # Excludes the Slack-app development surface (app / platform / manifest
    # / trigger / datastore / sandbox commands) — that's out of scope for
    # this configuration.
    "slack"              # parent/index — the map + `slack api` primer
    "slack-api"          # generic `slack api <method>` escape hatch
    "slack-auth"         # login / logout / list / revoke
    "slack-edit-message" # chat.update / chat.delete
    "slack-list-channels" # conversations.list (name → C…)
    "slack-list-users"   # users.list / users.lookupByEmail (name/email → U…)
    "slack-read-channel" # conversations.history
    "slack-react"        # reactions.add / reactions.remove / reactions.get
    "slack-search"       # search.messages
    "slack-send-message" # chat.postMessage / chat.postEphemeral / scheduleMessage
    "slack-thread"       # chat.postMessage + thread_ts, conversations.replies
    "slack-upload-file"  # files.getUploadURLExternal 3-step flow
    "try"
    "tui-context"
  ];

  # Productivity: writing + tone.
  productivity = [
    # no-em-dash — strip em-dashes / en-dash-as-em-dash / `--` from
    # any prose posted under the user's name (commits, MRs, tickets,
    # comments) so the output does not read as LLM-generated.
    "no-em-dash"
    "ste100"
  ];

  # Productivity/support: Jira / support-ticket resolution workflow.
  # The DAG is: jira-pick → jira-ticket (orchestrator; builds bead DAG
  # via beads-decompose + drives via beads-flow) → per-phase skills.
  support = [
    "jira-answer"       # phase:answer, phase:close
    "jira-deploy"       # phase:deploy env:{dev,staging,prod}
    "jira-explore"      # phase:explore
    "jira-fix"          # phase:fix-design, phase:implement
    "jira-merge"        # phase:merge, phase:tag (conditional)
    "jira-monitor"      # phase:verify env:{dev,staging,prod}
    "jira-pick"         # upstream: claim + On hold + Platform Capability
    "jira-review"       # phase:review (assign + @mention + loop)
    "jira-ticket"       # orchestrator
  ];

  anytypeToolbox = [
    # anytype-toolbox ships upstream-maintained skills for the `anyr`
    # CLI and connection setup. `any-mcp` deliberately excluded — MCP
    # is out of scope for this configuration.
    "anyr"
    "anytype-setup"
  ];

in
{
  # Skills are wired declaratively via home-manager's native
  # `programs.claude-code.skills` option (attrsOf (lines | path)).
  # Directory-typed values recursively install every file under the
  # skill dir (SKILL.md + references/ + assets/ + helper scripts) into
  # `~/.claude/skills/<name>/`, so no custom recursive-walk helper is
  # needed. Upstream skills (anytype-toolbox) are pulled straight from
  # the flake input's source tree — no vendoring.
  flake.modules.homeManager.ai-capability-skills =
    { lib, inputs, ... }:
    let
      inDir = parent: name: lib.nameValuePair name (parent + "/${name}");
      inCategory = category: inDir (skillsDir + "/${category}");
      inSupport = inDir (skillsDir + "/productivity/support");
      fromAnytypeToolbox =
        name:
        lib.nameValuePair name "${inputs.anytype-toolbox}/skills/skills/${name}";
    in
    {
      programs.claude-code.skills = lib.listToAttrs (
        map (inCategory "engineering") engineering
        ++ map (inCategory "productivity") productivity
        ++ map inSupport support
        ++ map fromAnytypeToolbox anytypeToolbox
      );
    };
}
