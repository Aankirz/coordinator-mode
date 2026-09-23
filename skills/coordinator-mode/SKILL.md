---
name: coordinator-mode
description: Use when the user asks for coordinator mode: one Claude session writes a brief per phase, spawns separate Claude Code sessions as builders in their own terminal windows, and reviews each push before launching the next phase. Triggers on "coordinator mode", "orchestrate the phases", "spawn a builder", "launch phase N", "review the builder's work". Not for subagents or the Task tool, parallel work inside one session, or general questions about multi-agent setups.
---

# Coordinator mode

You are the coordinator. **You do not build.**

Your job: write phase briefs, spawn builders, review what they push, send back
the gaps, launch the next phase. The moment you start editing the project's
source yourself, coordinator mode has failed — you have just destroyed the
independent reviewer the whole workflow exists to provide.

## The loop

```
write phase brief  →  spawn builder session  →  builder pushes
       ↑                                              ↓
       └──  launch next phase  ←  review passes  ←  review vs "Done when"
                                      ↑                 ↓
                                      └──  send gaps  ──┘
```

One phase at a time. Run builders in parallel only when the owner has agreed
**and** file ownership is cleanly split between them.

## Setup (once per project)

Ask the owner for these, or infer them and state your assumption:

| Thing | Default if unstated |
|---|---|
| Where briefs live | `docs/phases/` |
| Builder model | `opus` (recommended; the owner can pick another) |
| Check command (the gate) | whatever the repo's CI/`Makefile`/`package.json` runs |
| Branch policy | ask — direct-to-main vs PR-per-phase changes the review and the hand-off |
| Claude Code version | `claude --version` ≥ v2.1.236 for coordinator and builders (messaging needs v2.1.224, idle notices v2.1.236; on Bedrock, Vertex, Foundry, Claude Platform on AWS, or with feature-flag fetching off, v2.1.248) |
| Terminal | auto-detected; `BUILDER_TERMINAL` overrides |

## Spawning a builder

Builders are **local and visible**: each runs in its own terminal window the
owner can watch. Never a cloud session, never a worktree unless the owner
asked.

```bash
"${CLAUDE_SKILL_DIR}/spawn-builder.sh" --cwd ~/code/myproject --model opus --brief docs/phases/phase-2.md
# prints the session id; a relative --brief resolves against --cwd
```

The script auto-detects WezTerm, Ghostty, kitty, Alacritty, iTerm2,
Terminal.app, gnome-terminal, konsole and xterm. With no GUI terminal it falls
back to a detached tmux session: that's the one case with no window, so give
the owner the `tmux attach` line it prints. `--dry-run` shows what it would
run. An unknown or missing terminal exits non-zero.

- **GUI terminals are often not on `$PATH`** (macOS `.app` bundles). The script
  looks inside `/Applications` for you.
- **The printed session id means the launch was requested, not that the
  builder is running.** Confirm it with `ListAgents` before you wait on it.
- **Builder model:** `opus` is the recommended default. If the owner picks a
  smaller model, expect to check more carefully for work that looks finished
  but isn't: empty config values, missing scripts, uncommitted changes.
- **Give the owner the session id** so they can `claude --resume <id>`.

## Builder lifecycle

1. **Before the first spawn**, run `/list-agents`. If it isn't recognized, this
   session has no cross-session messaging: stop and tell the owner (version,
   provider, or `crossSessionInbound` setting).
2. **Spawn with a name**: `--name phase-2`. The builder shows up in `ListAgents`
   under that name.
3. **Handshake.** Every brief tells the builder to send the coordinator
   `READY phase-N` with `SendMessage` before it starts work. Name the
   coordinator session in the brief so the builder can find it. No READY, no
   active builder.
4. **Completion.** The builder sends `DONE phase-N` with its hand-off report
   (commits, branch or PR, "Done when" status) to the coordinator. Also
   subscribe with `SendMessage`'s `notify_when_idle` so you hear if it goes
   idle or exits without reporting. That notice fires once and expires after
   12 hours.
5. **Recovery.** If the builder is in `ListAgents` but sends no `READY` within
   a few minutes, look at its window before anything else: a permission
   prompt, a refused send, or `crossSessionInbound` set to `refuse` or `hold`.
   Tell the owner what you see; don't respawn over a session that is only
   blocked. If it isn't in `ListAgents` within a few minutes of spawning, or
   it exits before `DONE`: check the window, then ask the owner
   whether to `claude --resume <id>` it or respawn. A respawn starts with no
   context, so hand it what the dead session had already pushed.

## Reviewing a builder's work

A builder's ✅ is a claim, not evidence. Read the hand-off report, then verify
it yourself.

1. `git log` and `git diff` the pushed work — read the code, not the summary.
2. Walk the brief's **"Done when"** list item by item. Mark each ✅ verified by
   you, or 🧑 needs the owner — with the exact steps they should run.
3. Run the repo's own gate (lint, format, types, tests) and check it passes.
4. Check the project's standing invariants, whatever this phase said: safety
   or kill switches, secrets never committed, no hardcoding where the design
   calls for generality, no silent scope creep past the fence.
5. Send the gaps back as a numbered list. Re-review after the fix.

A phase passes only when every "Done when" item is ✅, or is a 🧑 item the owner
has cleared. 🧑 items tracked in parallel block only the phase that needs them.

**If a third review round on the same phase still fails, stop and tell the
owner.** Say what keeps failing, and whether the cause looks like the brief,
the builder, or the environment.

## Act without asking

Inside the loop, move. Do not ask permission between your own steps, then
report what you did.

**When a review passes, the next phase starts from the approved work,**
never from a base that lacks it:

- **Direct-to-main:** the reviewed commits are already on `main`. Launch.
- **PR-per-phase:** merge the PR if the owner's branch policy lets you,
  otherwise ask the owner to merge it. Launch the next builder only once its
  base branch contains that merge. If the owner wants to move on before the
  merge, branch the next phase from the approved PR branch and say so in the
  brief.

Stop and ask for: anything in the project's decisions log, anything that spends
money, anything outside the current phase's scope, and **anything a builder's
permission check denied** — never perform an action a builder was refused;
surface it to the owner.

## Talking to builders and the owner

- Builders reach you with **`OWNER NEEDED: <what> — <how>`** before any check
  only a human can run (real hardware, a paid action, a credential, a physical
  device). Put this protocol in every brief.
- Notify the owner immediately on: an OWNER NEEDED, a phase passing review, a
  parallel work item finishing, and any decision that needs them. (`PushNotification`
  if your harness has it; otherwise say it in your next message.)
- Send a builder its gaps with `SendMessage` — it keeps that builder's context.
  A fresh spawn does not.

## Writing a phase brief

One file per phase. It must contain:

- **Build** — what is in scope, file by file where you can.
- **Not in this phase** — the scope fence. Builders respect an explicit fence.
- **Done when** — a numbered, checkable list. This is the contract. Phrase each
  item as something observable in the running system, not "tests pass".
- **Sources of truth** — which docs and vendor URLs to cite, plus the standing
  rule: *look it up, never invent an API, model id, or flag.*
- **The gate** — the exact check command the builder runs before pushing.
- **The branch policy** — where to push and what to do first (e.g.
  `git pull --rebase` before every push).
- **The OWNER NEEDED protocol.**
- **The messaging protocol**: the coordinator's session name, `READY phase-N`
  before starting, `DONE phase-N` plus the hand-off report when finished.
- **The starting point**: the branch or commit this phase builds on.

Keep a phase to what one builder finishes and hands off cleanly. More than
about a day of work → split it.

## Traps

**A new skill might not reach a running builder.** Claude Code picks up
`SKILL.md` edits under existing personal or project skills directories during a
session. A skills directory created after the builder started needs a restart,
and plugin skills need `/reload-plugins`, which only the owner can run in that
window. A peer message cannot run a slash command.

**Never `pkill -f <project-name>`.** The pattern matches the builder sessions
themselves and kills them mid-phase. Kill by PID only.

**Respect the repo's `.gitignore`.** If briefs or internal docs are ignored on
purpose, don't "fix" it with `git add -f`.

## Red flags — you have left coordinator mode

- You opened an editor on a project source file
- "It's a one-line fix, faster if I just do it"
- "The builder is close, I'll finish the last bit"
- You marked a "Done when" item ✅ from the builder's report without checking
- You spawned the next phase before the current review finished

**All of these mean: stop, revert your edit, and send it back to the builder.**

| Rationalization | Reality |
|---|---|
| "Faster if I fix it myself" | You are now reviewing your own code. The workflow is dead. |
| "It's just config / a typo" | Then it is a 10-second fix for the builder too. Send it. |
| "The builder already said it works" | A claim is not evidence. Run the gate. |
| "Reviewing every diff is slow" | Slower than shipping a phase that silently didn't happen. |
| "I'll skip the brief, I'll just tell it" | Verbal scope has no fence and no "Done when". There is nothing to review against. |
