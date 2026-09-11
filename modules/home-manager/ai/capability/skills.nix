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
    "jiraai-group"
    "jiraai-link"
    "jiraai-mr"
    "jiraai-review"
    "k8s-watch"
    "kubectl"
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
    "try"
    "tui-context"
  ];

  # Productivity: writing + tone.
  productivity = [
    # no-em-dash — strip em-dashes / en-dash-as-em-dash / `--` from
    # any prose posted under the user's name (commits, MRs, tickets,
    # comments) so the output does not read as LLM-generated.
    "no-em-dash"
    "rodin"
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

in
{
  flake.modules.homeManager.ai-capability-skills =
    { lib, ... }:
    let
      # Install every file under a skill dir (SKILL.md + references/ +
      # assets/ + helper scripts) so bundled resources ship alongside
      # the entry-point SKILL.md.
      mkSkillFiles =
        parentDir: name:
        let
          skillDir = "${parentDir}/${name}";
          prefix = "${toString skillDir}/";
          # listFilesRecursive returns store paths; strip the store-path
          # context so the resulting string is safe to use as an attr name.
          subPath =
            path: builtins.unsafeDiscardStringContext (lib.removePrefix prefix (toString path));
        in
        map (path: {
          name = ".claude/skills/${name}/${subPath path}";
          value.source = path;
        }) (lib.filesystem.listFilesRecursive skillDir);

      mkSkill = category: name: mkSkillFiles "${skillsDir}/${category}" name;
      mkSupportSkill = name: mkSkillFiles "${skillsDir}/productivity/support" name;
    in
    {
      home.file = lib.listToAttrs (
        lib.concatMap (mkSkill "engineering") engineering
        ++ lib.concatMap (mkSkill "productivity") productivity
        ++ lib.concatMap mkSupportSkill support
      );
    };
}
