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

This section is the repository's explicit opt-in for worktree agents. An agent
in a worktree commits on the worktree branch and closes the children it
builds. It never runs `git push` or `bd dolt push`; those stay with Ash.

Finding work. Before each dispatch, Ash runs `bd ready -l human` and does
that work; mm-t10 is the first human step. Agents find work with
`bd ready -t epic -l first-cut --exclude-label human`, and after mm-m1 with
`bd ready -t epic -l second-cut --exclude-label human`. Until mm-t10 closes,
the first command returns only mm-t11. Plain `bd ready` also lists
constraint, human and second-cut beads. Never open a worktree for an epic
that is in_progress.

In the worktree. `claude -w <epic-id>` opens it. Claim the epic. Open or
continue its openspec build change. Build one child at a time, P0 first and
P2 last. A child's acceptance names the scenarios it builds; the change's
tasks.md lists every other scenario as `deferred: <bead id>`. When a scenario
needs an epic that Ash has not merged yet, the agent tests it over fixture
facts. A wiring bead (label `wiring`) in the later epic runs it end to end. Run `./verify`.
The first run in a new worktree is cold and can exceed 240 s; run it again,
because the warm run is the budget. The change README states the cold time.
When a child's tests pass, commit on the worktree branch and close the child
with `--reason` naming the commit. List each pending device check in the epic's
device-check bead (label `device-check`); Ash does the checks. Pass
`--type change` to `openspec validate` and `openspec show` for a build
change, because a build change can share its name with a main spec. The
change's delta ADDs each requirement that `openspec/specs` does not hold yet,
with only the scenarios that the build change builds. When `openspec/specs`
already holds the
requirement, the delta MODIFIES it with the full text copied from
`openspec/specs` on the branch.

After the worktree. Ash merges without squashing, so the commit named in each
`--reason` stays. Ash archives the change, pushes main and runs
`bd dolt push`. Ash closes the device-check bead after the device checks, and
then the epic. Each worktree starts its branch from local HEAD (`worktree.baseRef` is `head`
in `.claude/settings.json`). If Ash rejects
a branch, Ash reopens its closed children with `bd reopen`. Parallel worktrees
edit Today, `Packages/Package.swift` and the content version; Ash sets the
content version at the merge. Ash closes the milestones and the chores
mm-t44a and mm-t44b. `.claude/worktrees/` is git-ignored, so main stays clean
while worktrees exist.

The rules checklist. The agent writes a dated yes in the build change README
for each of the eleven constraint beads (`bd list -l constraint --all`). The
agent also writes one for safeguarding "Get support on every screen" on each
full screen that the change adds.

Rules for anything an agent writes: ASD-STE100 for every spec, design, task,
README line and bead. `product-rules` wins on conflict. `./verify` stays under
240 s and gains no check without asking Ash. Agents never open a worktree for
a `constraint` or `human` bead; Ash does the human beads.

A conflict between specs. Label the bead with `bd label add <id> human`. Add
the conflict and both spec paths with `bd comments add <id> "..."`. Stop work
on that bead and report to Ash. Never run `bd human respond` on a requirement
bead, because it closes the bead. Ash reviews flagged beads with
`bd human list` and puts each decision on the Midmorning Decisions page.

bd commands. Use full ids (`mm-t12.2`, never `mm-t1`). Search descriptions with
`bd list --desc-contains "<phrase>"` or `bd list -l spec:<name>`. Never run
bare `bd list --json`. File a follow-up with
`bd create --parent <epic> --no-inherit-labels -l spec:<name>,<cut>,phase:<n>,size:<S|M|L> --spec-id <path>#<heading>`;
add the label `requirement` only for a spec requirement. Expected `bd doctor`
warnings: Dolt remote, AGENTS.md, Dolt Status, Phantom Databases, Git
Upstream, Shared server, Claude Plugin. `__dolt_remote_info__` on origin is
not a code branch; never merge or delete it. Run `scripts/check-beads` by hand
to confirm every bead's spec heading and every `deferred` pointer.
