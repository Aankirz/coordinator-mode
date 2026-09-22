# Phase 2 — Short links API

Example brief for a small URL shortener (Node + TypeScript + SQLite). Phase 1
set up the project, the database connection, and the `links` table. Copy this
file into `docs/phases/`, then replace everything specific to this project.

## Starting point

Branch from `main` at the merge of PR #1 (Phase 1). Run `git log --oneline -1`
and confirm that the merge commit is there before you write anything.

## Build

- `src/routes/links.ts`: `POST /api/links` takes `{ "url": string }` and
  returns `201 { "code", "shortUrl" }`. `GET /:code` returns a `302` to the
  stored URL.
- `src/lib/code.ts`: generates a 7-character base62 code and retries on a
  collision.
- `src/lib/validate.ts`: accepts `http` and `https` URLs up to 2048 characters.
  Everything else gets `400 { "error" }`.
- `src/routes/links.test.ts`: tests for every item in "Done when" that a test
  can cover.
- `README.md`: add both endpoints to the API section, with one `curl` example
  for each.

## Not in this phase

- Custom aliases, expiry, click analytics, auth, rate limiting (Phases 3–5).
- Any change to the `links` schema. If you need one, stop and send
  `OWNER NEEDED`.
- New dependencies. The stdlib and what's already in `package.json` are enough.

## Done when

1. `curl -s -XPOST localhost:3000/api/links -d '{"url":"https://example.com"}' -H 'content-type: application/json'`
   returns `201` with a 7-character `code`.
2. `curl -sI localhost:3000/<that code>` returns `302` with
   `location: https://example.com`.
3. An unknown code returns `404`.
4. `ftp://x`, `not a url`, and a URL longer than 2048 characters each return
   `400` with a JSON `error`. Nothing is written to the database.
5. Posting the same URL twice gives two different codes, and both redirect.
6. A test forces a code collision and shows that generation retries instead of
   failing.
7. The server and tests read the `BASE_URL` for `shortUrl` from the
   environment. It isn't hardcoded anywhere.
8. The gate passes on the pushed commit.

## Sources of truth

- `docs/architecture.md`, the `links` schema in `src/db/schema.sql`.
- Node `URL` parsing: https://nodejs.org/api/url.html
- Look things up. Never invent an API, a flag, or a library function. If a doc
  and this brief disagree, stop and send `OWNER NEEDED`.

## The gate

```bash
npm run lint && npm run typecheck && npm test
```

Run it before every push. Never push a failing gate, and never skip or delete
a test to get it green.

## Branch policy

PR-per-phase. Work on `phase-2-links`. Run `git pull --rebase origin main`
before every push. Open one PR titled `Phase 2: short links API` and don't
merge it: the coordinator reviews it, and the owner merges.

## Messaging protocol

- The coordinator session is named `coordinator`. Find it with `ListAgents`.
- Before you start any work, send the coordinator `READY phase-2` with
  `SendMessage`.
- When you're done, send `DONE phase-2` followed by your hand-off report:
  - the PR link and the commits in it
  - each "Done when" item, with ✅ and the command you ran, or ❌ and why
  - anything you had to leave out, and the reason
- If the coordinator sends you gaps, fix them on the same branch, push, then
  send `DONE phase-2` again.

## OWNER NEEDED

Before any check that only a human can run (a credential, a paid action, a
schema change, a doc that contradicts this brief), stop and send the
coordinator:

```
OWNER NEEDED: <what you need> — <exact steps the owner should run>
```

Then wait. Don't work around it, and never retry an action a permission check
denied.
