
## 2026-09-22 — Reattribute coordinator-mode commit to Aankirz
- Amended commit eff7ca0 → 3845cee with author Aankirz <95562947+Aankirz@users.noreply.github.com>, force-pushed main; set repo-local git identity to Aankirz.

## 2026-09-22 — Fix launcher and docs per review
- spawn-builder.sh: AppleScript via argv, unsupported/missing terminal errors, --brief relative to --cwd, claude PATH check. SKILL.md/README: ${CLAUDE_SKILL_DIR} path, install paths, npx marked unpublished, reworded reload/model/escalation/tmux text. Commit af51bcd.

## 2026-09-22 — Second review fixes
- Manual install mkdir, PR hand-off rule, builder lifecycle (version, handshake, DONE, notify_when_idle, recovery), --name in launcher, plugin path via ${CLAUDE_SKILL_DIR}.

## 2026-09-22 — Third review fixes
- SKILL.md: no-READY recovery path, v2.1.248 provider/flag exception.

## 2026-09-22 — Example phase brief
- Added examples/phase-2.md (URL shortener phase, all required brief sections) and linked it from README.

## 2026-09-22 — README explainer diagram
- Added docs/how-it-works.svg (coloured-pencil sketch, embedded Caveat font) and replaced the ASCII loop in README with it.

## 2026-09-22 — Minimal diagram + icon
- Rebuilt docs/how-it-works.svg with ~8 words; added docs/icon.svg (red C + green tick) and README header.

## 2026-09-22 — Owl brand mark
- Replaced C+tick icon with an owl (tick beak, side-eye at builders) in docs/icon.svg and the diagram.

## 2026-09-22 — Cache-bust README images
- Renamed docs/icon.svg -> docs/owl.svg, docs/how-it-works.svg -> docs/owl-flow.svg.

## 2026-09-22 — Orbit mark
- Replaced owl with Orbit mark (hollow red ring over three solid blocks): docs/mark.svg, docs/flow.svg; README updated.

## 2026-09-22 — Animated flow diagram
- docs/flow.svg: 6s loop (SMIL dots, CSS code/tick/ring), static under prefers-reduced-motion.

## 2026-09-22 — Social preview PNG
- Added docs/social-preview.png (1280x640) and docs/mark.png (512px); copy on Desktop for upload.

## 2026-09-22 — Fresh repo
- Renamed old repo to Aankirz/coordinator-mode-old (private); created new public Aankirz/coordinator-mode with clean history, topics, description, social preview.

## 2026-09-22 — LinkedIn draft
- Rendered 18s MP4 of the flow animation; drafted post in LinkedIn composer (Ankit Kiran) with video, not posted.

## 2026-09-23 — Narrow skill description
- SKILL.md frontmatter: dropped catch-all trigger clause, added explicit non-triggers (subagents/Task tool, in-session parallel work, general multi-agent questions).
