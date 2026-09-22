#!/usr/bin/env node
// Installs the coordinator-mode skill into ~/.claude/skills (or ./.claude/skills with --project).
const fs = require('fs');
const os = require('os');
const path = require('path');

const SKILL = 'coordinator-mode';
const src = path.join(__dirname, '..', 'skills', SKILL);
const project = process.argv.includes('--project');
const root = project ? process.cwd() : os.homedir();
const dest = path.join(root, '.claude', 'skills', SKILL);

if (!fs.existsSync(src)) {
  console.error(`missing skill source at ${src}`);
  process.exit(1);
}
if (fs.existsSync(dest) && !process.argv.includes('--force')) {
  console.error(`${dest} already exists. Re-run with --force to overwrite.`);
  process.exit(1);
}

fs.mkdirSync(path.dirname(dest), { recursive: true });
fs.cpSync(src, dest, { recursive: true, force: true });
for (const f of fs.readdirSync(dest)) {
  if (f.endsWith('.sh')) fs.chmodSync(path.join(dest, f), 0o755);
}

console.log(`Installed ${SKILL} -> ${dest}`);
console.log(`Start a Claude Code session and say "coordinator mode" to use it.`);
