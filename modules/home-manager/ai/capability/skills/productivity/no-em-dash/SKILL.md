---
name: no-em-dash
description: Never write em-dashes (—), en-dashes used as em-dashes (–), or double-hyphens (--) as em-dash substitutes in prose that the user will publish under their name. Rewrite with comma, semicolon, colon, parentheses, or a period instead. Triggers whenever drafting or editing text destined for external humans — git commit bodies, PR/MR descriptions, code-review comments, GitHub/GitLab issue comments, Jira comments and answers, Slack/email drafts, release notes, changelog entries, blog posts, ticket updates, docs written for humans (not code comments) — and whenever the user says "post this", "comment", "reply", "write the MR body", "commit message", "ticket answer", "draft the response", "draft the answer", "compose this", "write it up for", "publish this", or shows a draft to review. Does NOT trigger for code, code comments, log lines, config files, or when the user has explicitly asked for em-dashes.
---

# no-em-dash — kill the LLM tell before it ships

Em-dashes (`—`), en-dashes used as em-dashes (`–`), and the ASCII
double-hyphen (`--`) used as an em-dash are one of the loudest tells
that a piece of prose was written by an LLM. The user does not want
their commit bodies, MR descriptions, ticket answers, or comments to
read like an AI wrote them. Strip them at the source.

## The rule

In any prose destined to be posted under the user's name, do not emit:

- `—` (U+2014 em-dash)
- `–` (U+2013 en-dash) when used as a sentence-level pause (en-dash for
  numeric ranges like `10–20` is fine)
- `--` (two ASCII hyphens) used as an em-dash substitute
- ` -- ` with surrounding spaces used the same way

This applies to text I generate AND to text the user drafts and asks me
to review, polish, translate, or rewrite. If a draft contains any of
the above, replace them before returning the text.

## Where it applies

Reach for this whenever the output is prose a human will read:

- git commit bodies (the title is short enough it rarely needs one anyway)
- MR / PR descriptions and reply comments
- code-review comments and review replies
- GitHub / GitLab issue comments, Jira comments, Jira answers
- Slack messages, email drafts, DMs
- release notes, changelogs, blog posts, announcements
- prose docs (README body text, ADRs, runbooks) — not the code inside them

## Where it does NOT apply

- Source code, code comments, log messages, config files
- CLI flags (`--verbose` is a flag, not punctuation)
- Numeric or date ranges (`10–20`, `Mon–Fri`)
- Quoted text that is not the user's — do not silently edit a quote
- Cases where the user explicitly asks for em-dashes ("keep the em-dash",
  "I want the em-dash there")

## What to write instead

Pick the substitute that matches the actual grammatical role the dash
was playing. There is always one that fits.

| Original                                            | Better                                                |
| --------------------------------------------------- | ----------------------------------------------------- |
| `We rolled it back — the metric was worse.`         | `We rolled it back. The metric was worse.`            |
| `The fix — a two-line patch — landed on Friday.`    | `The fix (a two-line patch) landed on Friday.`        |
| `Only one thing matters — latency.`                 | `Only one thing matters: latency.`                    |
| `Retry on 5xx — never on 4xx.`                      | `Retry on 5xx, never on 4xx.`                         |
| `Add the flag -- default off -- and ship it.`       | `Add the flag, default off, and ship it.`             |
| `Three options — A, B, C.`                          | `Three options: A, B, C.`                             |

Rules of thumb:

- Parenthetical aside → parentheses `( ... )` or a comma pair
- Sudden break / abrupt continuation → period, start a new sentence
- Setup for a list or a punchline → colon `:`
- Two clauses in tension → semicolon `;` or split into two sentences

If none of those feel right, the sentence probably wants to be two
sentences.

## Self-check before returning any user-facing prose

Before emitting text that will end up in a commit body, an MR
description, a ticket, a comment, or a Slack message, scan it for `—`,
` – ` (spaced en-dash), and ` -- `. If any are present, rewrite them
using the substitutes above. Then emit.

This includes text produced by other skills (commit-rationale,
twg jira workitem comment create, jira-answer, glab-mr-*, etc.) — the ban applies to
the final output regardless of which pipeline generated the draft.

## Composition with other skills

- `commit-rationale` shapes the commit body content; this skill polices
  its punctuation before `git commit` runs.
- `mm-skills-git-commit-craft` shapes titles; titles almost never need
  a dash of any kind, so this skill will usually be a no-op there.
- `ste100` (Simplified Technical English) already forbids most
  em-dash-worthy sentence structures; when writing in ste100 mode
  em-dashes should not appear at all — this skill is the second net.
- `jira-answer`, `twg jira workitem comment create`, MR-body skills: run this skill's
  self-check as the last step before posting.
