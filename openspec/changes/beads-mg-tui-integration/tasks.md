## 1. Pre-flight verification

- [ ] 1.1 Verify `mardi-gras` is inheritable from `inputs.llm-agents.packages.${system}` by running `nix eval --impure --expr 'let f = builtins.getFlake "/home/juliendauliac/ghq/github.com/Dauliac/dotfiles"; in f.inputs.llm-agents.packages.x86_64-linux.mardi-gras.meta.mainProgram'` — expect `"mg"`. Verification: exit 0, stdout contains `mg`.
- [ ] 1.2 Verify no existing engineering-skill named `mg-watch` — `test ! -d modules/home-manager/ai/capability/skills/engineering/mg-watch`. Verification: exit 0.
- [ ] 1.3 Verify `herdr-tui` has no `find` subcommand (dedup must use `herdr` primitives) — `herdr-tui find 2>&1 | grep -q "unknown subcommand"`. Verification: exit 0.

## 2. Package + alias re-add (parallel-executable with §3)

- [ ] 2.1 Edit `modules/packages/default.nix` — add `mardi-gras # terminal UI for beads with parade-inspired workflow view (CLI: mg)` to the `inherit (llmAgentsPkgs) ...` block, alphabetically after `hunk` and before `openspec`. Verification: overlay eval returns `pkgs.mardi-gras.meta.mainProgram = "mg"`.
- [ ] 2.2 Edit `modules/home-manager/ai/packages.nix` — add `mardi-gras # terminal UI for the beads issue tracker (CLI: mg)` to the AI package list next to `beads-viewer`. Verification: `nix eval` shows the package attribute path resolves; `home-manager packages | grep mardi-gras-` will list it post-switch.
- [ ] 2.3 Edit `modules/home-manager/aliases.nix` — insert the `mg` alias next to the `bv` alias with the flush-before-launch shell sequence: `mg = "${pkgs.beads}/bin/bd sync --flush-only && ${pkgs.mardi-gras}/bin/mg"`. Include a comment referencing the openspec change slug. Verification: `nix eval` of the aliases attrset resolves; `zsh -ic 'type mg'` post-switch shows the alias.

## 3. mg-watch skill file (parallel-executable with §2)

- [ ] 3.1 Create `modules/home-manager/ai/capability/skills/engineering/mg-watch/SKILL.md`. See design.md D1-D4 for the shape; verification: file exists, YAML frontmatter valid, description <500 chars.
- [ ] 3.2 Register `"mg-watch"` in `modules/home-manager/ai/capability/skills.nix` engineering array, alphabetically after `k8s-watch` and before `kubectl`. Verification: `grep -n '"mg-watch"' skills.nix` returns line 91-ish.
- [ ] 3.3 Verify the skill file will be picked up by the loader — `nix eval --impure --raw --expr` on the resolved `home.file.".claude/skills/mg-watch/SKILL.md".source` path. Verification: eval returns a store path that reads back to the SKILL.md content.

## 4. Cross-reference wiring

- [ ] 4.1 Edit `modules/home-manager/ai/capability/skills/engineering/beads/SKILL.md` — append `- Pair with `mg-watch` for a live side-panel view of task state.` to the "Composes with" section (or equivalent). Verification: `grep -n mg-watch beads/SKILL.md` matches.
- [ ] 4.2 Edit `modules/home-manager/ai/capability/skills/engineering/beads-flow/SKILL.md` — same cross-reference edit. Verification: `grep -n mg-watch beads-flow/SKILL.md` matches.
- [ ] 4.3 Design-test the dedup shell primitive — run `herdr pane list --workspace $HERDR_WORKSPACE_ID 2>/dev/null | jq -r '.panes[].label // empty' | grep -q '^mg-'`. Verification: exits 0 or 1 without error; documents the primitive in SKILL.md body.
- [ ] 4.4 Ensure the SKILL.md body's dedup + no-`.beads/` bail-out patterns are both present. Verification: grep the SKILL.md for `-d .beads` (bail-out) AND `mg-` label prefix (dedup) — both should match.

## 5. Deploy + verify

- [ ] 5.1 Run `xi home switch .` on `ML-PF603JJ8` and confirm no evaluation errors. Verification: exit 0, `home-manager packages | grep -E 'mardi-gras-|beads-viewer-'` lists both.
- [ ] 5.2 Live-smoke `mg` against post-migration `.beads/` — invoke `mg` (or via `alias`) in the dotfiles repo, confirm it opens without a schema error and lists at least one bead. Non-interactive check via `mg --version` if `mg` has one; else visual confirmation in a herdr split. Verification: exit 0.
- [ ] 5.3 Verify `~/.claude/skills/mg-watch/SKILL.md` symlink exists and points into the nix store. Verification: `readlink -f ~/.claude/skills/mg-watch/SKILL.md` returns a `/nix/store/*` path.
- [ ] 5.4 Verify skill-loader materialized `mg-watch` — `ls ~/.claude/skills/mg-watch/` shows the SKILL.md and any bundled resources. Verification: at least SKILL.md present.
- [ ] 5.5 Run `openspec validate beads-mg-tui-integration --strict` — expect exit 0 ("Change is valid"). Verification: exit 0.

## 6. Final wrap

- [ ] 6.1 Manual trigger test: in a fresh Claude session in a repo with `.beads/`, mention "bd ready" and confirm the word-match self-check surfaces `mg-watch`. If it doesn't, revise the SKILL.md `description:` phrases in step 3.1 and re-verify. Verification: `mg-watch` appears in the skill self-check output.
- [ ] 6.2 If manual trigger works, prepare commits per the mm-skills-git-commit-craft skill: (a) openspec artifacts, (b) package + alias re-add, (c) mg-watch skill file + registration, (d) cross-references. Verification: `git log --oneline -4` shows 4 commits with conventional-commit titles.
