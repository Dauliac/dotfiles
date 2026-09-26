---
name: ste100
description: Write in ASD-STE100 Simplified Technical English with a direct, military tone. Use when the user asks for STE, ASD-STE100, simplified English, plain writing, "military tone", "no fluff", "keep it short", or when producing procedures, runbooks, alerts, incident reports, checklists, or CLI help text. Short sentences. Approved words. One order per line. No hedging.
---

# ste100 — write like a field manual

ASD-STE100 is the aerospace industry's Simplified Technical English
standard. Its job is to make procedures unambiguous for readers under
stress, working in a second language, or reading on a small screen.

Apply it whenever the reader needs to act, not admire prose.

## The rules (non-negotiable)

1. **Short sentences.** Procedural: max 20 words. Descriptive: max 25.
2. **One instruction per sentence.** No "and then also".
3. **Active voice, imperative.** "Restart the service." Not "the service
   should be restarted".
4. **Present tense only.** No "will", "would", "might have been".
5. **One meaning per word.** Pick one term per concept and stick to it.
   Do not swap "container" and "pod" mid-doc.
6. **No noun clusters longer than three words.** "Kubernetes cluster
   config file" is fine. "Kubernetes cluster ingress config file
   template" is not — split it.
7. **Approved vocabulary.** Prefer short, common words. Reject synonyms
   that add no meaning.
8. **No idioms, metaphors, slang, jokes.** "Kick the tires" is banned.
   Say "test it".
9. **No hedging.** Delete "perhaps", "somewhat", "it seems", "arguably",
   "I think".
10. **Warnings before actions.** Put the danger first, the command
    second.

## Military tone rules

- **Imperatives, not suggestions.** "Run X." Not "You might want to run X".
- **Facts, not opinions.** "The service is down." Not "The service
  appears to possibly be down."
- **Numbers, not adjectives.** "3 retries, 5s timeout." Not "a few
  retries with a short timeout."
- **State the failure mode explicitly.** "If X returns non-zero, stop."
- **No apologies. No preamble.** Get to the order.

## Approved verbs (pick from these first)

`add`, `check`, `close`, `connect`, `disconnect`, `do`, `find`, `get`,
`hold`, `install`, `keep`, `let`, `make`, `move`, `obey`, `open`,
`operate`, `push`, `pull`, `put`, `read`, `release`, `remove`, `replace`,
`send`, `set`, `show`, `start`, `stop`, `test`, `turn`, `use`, `write`.

## Banned words / phrases

- "utilize" → **use**
- "in order to" → **to**
- "prior to" → **before**
- "subsequently" → **then**
- "leverage" → **use**
- "facilitate" → **help** or **let**
- "endeavor" → **try**
- "aforementioned" → cut it
- "please note that" → cut it
- "it is important to" → cut it
- adverbs ending in -ly that add nothing ("basically", "essentially",
  "actually") → cut them

## Structure for procedures

```
GOAL: <one line — what the reader will achieve>

WARN: <danger, if any>

STEPS:
1. <verb> <object>. <optional one-clause detail>
2. <verb> <object>.
3. ...

CHECK: <how to know it worked — one line>
FAIL: <what to do if it did not — one line>
```

## Examples

**Bad (rewrite):**

> It would probably be a good idea to first consider stopping the
> service before you go ahead and try to modify the config, since
> otherwise there could potentially be some kind of conflict.

**Good:**

> Stop the service before you edit the config. A running service
> locks the file.

---

**Bad:**

> The deployment pipeline seems to have possibly encountered some sort
> of issue, and it might be helpful to investigate what happened.

**Good:**

> The deployment failed at step 3. Read `deploy.log`. Report the last
> error line.

## When NOT to use STE

- Marketing copy, blog posts, user-facing explanations that need warmth.
- Chat responses where the user asked an open-ended question and wants
  discussion, not orders.
- Anywhere the user explicitly asks for a conversational tone.

If unsure whether the reader wants prose or a procedure, ask once. Then
commit to one register — do not mix them in the same document.

## Self-check before you ship

- [ ] Every sentence has one verb in the imperative or one clear
      statement of fact.
- [ ] No sentence over 20 words.
- [ ] No banned word from the list above.
- [ ] No hedges. No apologies. No preamble.
- [ ] The reader can act from line 1 without scrolling.
