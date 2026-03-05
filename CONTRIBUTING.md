# Contributing to cc-bridle

## Development Environment

**Requirements:**
- Node.js 18+ (check with `node --version`)
- [bats-core](https://github.com/bats-core/bats-core) for tests:
  ```bash
  brew install bats-core   # macOS
  npm install -g bats      # or via npm
  ```

## Directory Structure

```
cc-bridle/
├── hooks/
│   ├── hooks.json          # Hook event registrations
│   ├── pre-tool.sh         # PreToolUse chain: env-guard → git-guard → danger-label
│   ├── post-tool.sh        # PostToolUse chain: stats → hook-timer
│   └── session.sh          # SessionStart/Setup handler
├── scripts/
│   ├── danger-dict.json    # Global danger pattern dictionary
│   ├── danger-label.js     # Warning annotator (never blocks)
│   ├── detect-rules.json   # Stack detection rules
│   ├── env-detect.js       # Tech stack detector
│   ├── env-guard.js        # Package manager guard (blocks)
│   ├── git-guard.js        # Git operation guard (blocks)
│   ├── git-guard-wizard.js # Interactive git guard configurator
│   ├── hook-timer.js       # Hook execution timer
│   ├── hooks-conflict.js   # Plugin conflict detector
│   ├── init.sh             # Data directory initializer
│   ├── plan-template.md    # Phase plan quality standard
│   ├── preflight.js        # Session permission previewer
│   ├── redirect-rules.json # Package manager redirect rules
│   ├── skill-scan.js       # SKILL.md security scanner
│   └── stats.js            # Usage statistics recorder
├── skills/
│   ├── add-stack/          # /cc-bridle add-stack
│   ├── githooks/           # /cc-bridle githooks
│   ├── hook-timer/         # /cc-bridle hook-timer
│   ├── plan-review/        # /cc-bridle plan-review
│   ├── plan-review-all/    # /cc-bridle plan-review-all
│   ├── plan-split/         # /cc-bridle plan-split
│   ├── preflight/          # /cc-bridle preflight
│   ├── scan/               # /cc-bridle scan
│   └── stats/              # /cc-bridle stats
└── tests/
    ├── helpers/common.bash  # Shared test utilities
    ├── phase-1.bats
    ├── phase-2-danger.bats
    ├── phase-2-preflight.bats
    ├── phase-3.bats
    ├── phase-4.bats
    ├── phase-5-scan.bats
    ├── phase-5-conflict.bats
    ├── phase-6.bats
    └── phase-8.bats
```

## Adding a New Feature

1. **Create the script** in `scripts/` (Node.js CommonJS, `require()`)
2. **Register in hooks** — update `hooks/pre-tool.sh` (PreToolUse) or `hooks/post-tool.sh` (PostToolUse)
3. **Create a skill** in `skills/<name>/SKILL.md` with YAML frontmatter
4. **Write tests** in `tests/phase-N.bats`
5. **Update phase plans** in `docs/plans/phase-N.md`

## Running Tests

```bash
# All tests
bats tests/

# Single phase
bats tests/phase-1.bats

# Multiple phases
bats tests/phase-2-danger.bats tests/phase-3.bats
```

## Dictionary Contributions

### Adding Danger Patterns

Edit `scripts/danger-dict.json`. Patterns are case-insensitive regex strings:

```json
{
  "critical": ["your-pattern-here"],
  "warning": ["your-warning-pattern"]
}
```

No restart needed — `danger-label.js` reads the file on every invocation.

### Adding Stack Detection Rules

Edit `scripts/detect-rules.json`:

```json
{
  "id": "my-stack",
  "files_all": ["required-file.toml"],
  "files_any": ["option-a.lock", "option-b.lock"],
  "files_none": ["conflicting-file"]
}
```

Then add redirect rules in `scripts/redirect-rules.json`.

### Per-project overrides

Users can add project-specific rules without touching global files:
- `~/.claude/cc-bridle/projects/<cwd-hash>/danger-dict-extra.json`
- `~/.claude/cc-bridle/projects/<cwd-hash>/detect-rules-extra.json`

## PR Guidelines

**Branch naming:** `feat/<description>`, `fix/<description>`, `docs/<description>`

**Commit messages:** Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
feat: add ruby stack detection
fix: handle missing env.json gracefully
docs: update CONTRIBUTING with new stack guide
```

**Requirements before submitting:**
- `bats tests/` passes with zero failures
- New scripts covered by bats tests
- `jq . hooks/hooks.json` and `jq . plugin.json` return valid JSON
- Dictionary additions are regex-safe (test with `node -e "new RegExp('your-pattern')"`)
