# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:1105d646 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/core-concepts/sync-concepts.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->


## Build and test

`./verify` is the contract for done. Run it before every commit. It runs
the three checks below and exits non-zero on any failure.

```bash
./verify                                                    # all checks, under 240s
swift test --package-path Packages                          # every module, on macOS
xcodebuild -project App/Midmorning.xcodeproj -scheme Midmorning \
  -destination 'generic/platform=iOS Simulator' build       # the app, simulator only
openspec validate --all --strict                            # every change and spec
```

To run the app: build with a named simulator destination, then install and
launch `uk.midmorning.app` with `xcrun simctl`. The entry point is
`App/Midmorning/MidmorningApp.swift`.

## Worktrees and beads

One worktree per epic. Dispatch with `bd ready -t epic -l first-cut`; the
epic's children are its checklist, P0 first, P2 last. `claude -w <epic-id>`
opens the worktree. In it: claim the epic, open or continue its openspec
build change, build one child at a time, run `./verify`, commit on the
worktree branch, and close each child with `--reason` naming the commit.
Ash merges the branch, archives the change and closes the epic.

Rules for anything an agent writes: ASD-STE100 for every spec, design,
task, README line and bead; `product-rules` wins on conflict; a conflict
between specs goes to `bd human <id>` and the Midmorning Decisions page,
never a silent choice; `./verify` stays under 240s and gains no check
without asking Ash. `constraint` and `human` beads are not dispatched.

bd notes: use full ids (`mm-t12.2`, never `mm-t1`); search with
`bd search --desc-contains` or `bd list -l spec:<name>`; never bare
`bd list --json`; file follow-ups with
`bd create --parent <epic> --no-inherit-labels -l requirement,spec:<name>,<cut>`;
`bd doctor` warnings about the Dolt remote and AGENTS.md are expected.
Run `scripts/check-beads` by hand to confirm every bead's spec heading exists.
