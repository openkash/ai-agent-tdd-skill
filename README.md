# TDD Skill for Claude Code

A structured, project-agnostic Test-Driven Development process for
[Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Tests give Claude a self-verification loop -- the
[highest-leverage pattern](https://code.claude.com/docs/en/best-practices#give-claude-a-way-to-verify-its-work)
for agentic coding. This skill wraps that insight in a repeatable
process that follows Claude Code's
[Explore -> Plan -> Implement -> Commit](https://code.claude.com/docs/en/best-practices#explore-first-then-plan-then-code)
workflow.

## What It Does

When you invoke `/tdd`, Claude follows a 6-phase process:

```
Phase 1: Analysis        Understand the request, explore code, check standards
Phase 2: Planning        Decompose into chunks, dependency graph, get approval
Phase 3: Pre-Test        Write failing tests (or verify existing coverage)
Phase 4: Implementation  Write production code to make tests pass
Phase 5: Post-Test       Verify chunk tests pass, run full suite on last chunk
Phase 6: Quality         8-point checklist, post-implementation docs
```

Phases 3-5 repeat per chunk. Small features use a shortcut that skips
chunking and planning.

## When to Use It

| Scope | Approach |
|---|---|
| Trivial (typo, rename, version bump) | Don't use this skill -- just ask Claude directly |
| Small (single-file logic, simple bug fix) | `/tdd` with small feature shortcut |
| Medium+ (multi-file, unfamiliar code) | `/tdd` full process |
| Large (cross-cutting, multi-session) | `/tdd` full process + JSON tracker |

**Rule of thumb:** If you can describe the diff in one sentence,
skip the skill. If you need tests to verify correctness, use it.

## Installation

### 1. Copy the skill into your project

```bash
# From your project root
mkdir -p .claude/skills/tdd
cp -r /path/to/tdd-skill/SKILL.md .claude/skills/tdd/
cp -r /path/to/tdd-skill/references/ .claude/skills/tdd/
```

Or clone and copy:

```bash
git clone https://github.com/openkash/ai-agent-tdd-skill.git /tmp/tdd-skill
mkdir -p .claude/skills/tdd
cp /tmp/tdd-skill/SKILL.md .claude/skills/tdd/
cp -r /tmp/tdd-skill/references/ .claude/skills/tdd/
```

Claude Code auto-discovers skills in `.claude/skills/`. Once copied,
the skill appears in the `/` menu and Claude can invoke it
automatically when relevant.

### 2. Create your PROJECT.md

Copy the template and fill in your project's details:

```bash
cp /tmp/tdd-skill/PROJECT.md .claude/skills/tdd/PROJECT.md
```

Or start from an example config:

```bash
# Pick your stack
cp /tmp/tdd-skill/project-configs/android-kotlin.md \
   .claude/skills/tdd/PROJECT.md
```

Edit `PROJECT.md` with your test commands, architecture rules, and conventions.

### 3. Use it

Invoke the skill directly:

```
/tdd implement the user search feature
/tdd fix the pagination bug
/tdd refactor auth to use OAuth2
```

Or let Claude invoke it automatically when you describe work that
needs test verification:

```
I need to add rate limiting to the API endpoints. Research the
codebase first, then implement with tests.
```

## File Structure

```
tdd-skill/
├── SKILL.md                     # Core TDD process (project-agnostic)
├── PROJECT.md                   # Template, copy and customize
├── references/
│   ├── chunk-template.md        # How to decompose features into chunks
│   ├── tracker-schema.md        # JSON tracker for multi-session work
│   └── quality-checklist.md     # 8-point quality verification checklist
└── project-configs/             # Example PROJECT.md for common stacks
    ├── android-kotlin.md        # Android / Kotlin / Compose / Hilt
    ├── typescript-node.md       # TypeScript / Node.js / Jest or Vitest
    ├── python-pytest.md         # Python / pytest / FastAPI or Django
    └── rust-cargo.md            # Rust / Cargo
```

## What Goes Where

| Content | Location | Committed? |
|---------|----------|------------|
| TDD process (universal) | `SKILL.md` | Yes |
| Project config (your stack) | `PROJECT.md` | Your choice |
| Chunk decomposition guide | `references/chunk-template.md` | Yes |
| Tracker schema | `references/tracker-schema.md` | Yes |
| Quality checklist | `references/quality-checklist.md` | Yes |
| Active tracker (work in progress) | Your docs directory | No (local) |

## Key Concepts

### Chunks

Features get broken into independently testable implementation
chunks. Each chunk has explicit dependencies, test files, and
resume instructions so work can pick up where it left off. See
[chunk-template.md](references/chunk-template.md).

### JSON Tracker

For multi-session features (3+ chunks), a JSON tracker file
tracks progress. A new session reads the tracker, finds the
next pending chunk, and continues. See
[tracker-schema.md](references/tracker-schema.md).

### 8-Point Quality Checklist

Applied twice: once to the plan (Phase 2.5, catching design
bugs before code) and once after implementation (Phase 6).
See [quality-checklist.md](references/quality-checklist.md).

### Small Feature Shortcut

Single-file or few-file changes skip chunking, planning, and
tracker creation. The process collapses to: Analysis -> Pre-Test
-> Implement -> Post-Test -> Quality Verification.

### Lessons Learned

The skill includes 16 lessons from real TDD sessions. Things
like false positive tests, dead code left behind, constructor
cascading breakage. Applied every time.

## Customization

### Adding Project-Specific Lessons

Add lessons to your `PROJECT.md` or append to your copy of
`SKILL.md` in the Lessons Learned section. Keep the format:

```markdown
17. **Your lesson title** --
    What happened, why it matters, what to do differently
```

### Modifying the Quality Checklist

The 8 points are intentionally generic. Customize them in your
`PROJECT.md` under "Standards to Verify" and "Blindspots to Check".
The checklist references those sections.

### Adjusting the Test Strategy Table

The test strategy table in Phase 3.1 maps chunk types to test
approaches. If your project has additional conventions (snapshot
tests for components, contract tests for APIs, etc.), add rows
to your copy.

## Origin

Extracted from an open source calendar app where it was used
across RFC compliance work, CalDAV sync, and UI features. The
project-specific parts were swapped out for a pluggable
`PROJECT.md` so the core process works with any stack.

## License

Apache License 2.0. See [LICENSE](LICENSE).
