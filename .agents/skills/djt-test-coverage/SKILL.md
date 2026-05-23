---
name: djt-test-coverage
description: "Audit test coverage across the codebase, generate a checkbox report of missing tests, then implement selected additions on a branch. /djt-test-coverage [path]"
trigger: /djt-test-coverage
---

# /djt-test-coverage

Analyze test coverage across the codebase, produce a prioritized checkbox report of gaps, then implement the selected additions on a dedicated branch.

## Usage

```
/djt-test-coverage                    # audit entire project
/djt-test-coverage src/               # audit a specific directory
/djt-test-coverage src/auth/login.ts  # audit a specific file
```

## Workflow Overview

This skill runs in two phases separated by user confirmation:

1. **Audit** — scan, analyze, and write a coverage gap report with checkboxes
2. **Implement** — re-read the populated report, implement only checked items, commit on a branch

---

## Phase 1 — Audit

### Step 1: Detect the Testing Landscape

Before evaluating any file, identify the testing framework(s) in use. Read:

- `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `project.godot`, or equivalent manifest
- Any config files: `jest.config.*`, `vitest.config.*`, `pytest.ini`, `setup.cfg`, `.mocharc.*`, `karma.conf.*`, `jasmine.json`, `phpunit.xml`, `rspec`, `gut_config.cfg`, etc.
- Any existing test files (look for `tests/`, `__tests__/`, `spec/`, `test/`, `*.test.*`, `*.spec.*`, `test_*.gd`, etc.)

From this, determine:

- **Framework(s)**: e.g., Jest, Vitest, pytest, Go test, RSpec, GUT, PHPUnit
- **Test runner command**: e.g., `npm test`, `pytest`, `go test ./...`
- **Test location convention**: co-located vs. separate `tests/` directory
- **Naming convention**: `*.test.ts`, `test_*.py`, `*_test.go`, `test_*.gd`, etc.
- **Limitations and hard boundaries**: Record what the framework cannot or should not test (e.g., UI rendering in unit tests, scene-tree code in GUT unit tests, I/O in pure unit suites). These boundaries constrain what counts as a "missing test."

### Step 2: Map Source Files to Test Files

For every source file in scope:

1. Locate its corresponding test file (by convention).
2. If no test file exists → mark as **No Coverage**.
3. If a test file exists → read it and evaluate depth (see Step 3).

Skip files that are not testable by nature:
- Pure configuration/constants files with no logic
- Auto-generated code (migrations, protobuf outputs, build artifacts)
- Framework entry points / bootstrapping files (e.g., `main.ts`, `index.html`, `_app.tsx`) — note the skip reason in the report

### Step 3: Evaluate Coverage Depth

For each source file with a corresponding test file, evaluate what is actually tested.

Identify the following gaps, scoped to what the detected framework can handle:

#### A — Untested Public API
Every exported function, method, class, and module must have at least one test covering its primary behavior. Flag any public symbol with no corresponding test case.

#### B — Unhappy Paths and Error Handling
For every `try/catch`, error return, validation branch, or conditional guard, there must be a test that exercises the failure path. Flag any error path with no corresponding test.

#### C — Boundary and Edge Cases
- Numeric boundaries: zero, negative, max/min values
- Empty inputs: empty string, empty array, null, undefined, None
- Single-element collections
- Off-by-one conditions in loops or slices
Flag any function that processes collections or has numeric thresholds with no boundary test.

#### D — State Mutations
Any function that mutates shared or persistent state (database writes, file writes, cache updates, Autoload state in Godot) must be tested for both the mutation itself and any observable side effects. Flag state-mutating functions with no test asserting the resulting state.

#### E — Integration Seams
Calls to external systems (HTTP clients, database adapters, file system, OS calls, message queues) are integration seams. They require either:
- An integration test that exercises the real seam, OR
- A unit test that stubs/mocks the seam and asserts the correct call is made

Flag any integration seam with neither.

#### F — Async / Concurrency
Any async function, coroutine, promise chain, goroutine, or concurrent operation must be tested with explicit await/resolution assertions. Synchronous test wrappers that ignore async behavior are not sufficient. Flag async code with no async-aware test.

#### G — Branch Coverage Gaps
For any conditional block (`if/else`, `switch/match`, `ternary`) with more than two branches, each branch must be exercised by at least one test. Flag conditionals where fewer than all branches are covered.

### Step 4: Write the Coverage Gap Report

Write the report to `.agents/output/coverage/<scope>-<YYYY-MM-DD>.html`. Use the standard HTML shell from the **HTML Output Convention** in AGENTS.md (`badge-coverage`, depth-1 stylesheet path `../assets/style.css`). Bootstrap the stylesheet first if not present.

Structure the report with these sections:

**Header** — `.doc-header` with `badge-coverage` badge, date, and title "Test Coverage Audit — \<scope\>".

**Framework Boundaries** (`<h2>`) — `.callout.info` block listing what's in/out of scope.

**Coverage Summary** (`<h2>`) — `<table>` with columns Status / Count (Fully covered, Partially covered, No coverage, Skipped).

**Missing Tests — Prioritized Checklist** (`<h2>`) — Include this instruction paragraph: *"Check the boxes for additions you want implemented, then run: `/djt-test-coverage --apply .agents/output/coverage/<this-file>.html`"*

Render four sub-sections (Critical / High / Medium / Low), each as `<h3>` followed by a `<ul class="checklist">`. Each `<li>` must use `data-gap-id` for machine readability and include the file path in `<code>`, the function name, the gap category code in brackets, and the explanation. Mark severity via `class="priority-high"` (Critical/High) or leave default (Medium/Low). Use `<input type="checkbox">` inside each `<li>` so the Apply phase can parse checked state.

**Fully Covered Files** (`<h2>`) — `.files-list` of `.file-chip` elements.

**Skipped Files** (`<h2>`) — `.files-list` of `.file-chip` elements with brief reason in a `<span>`.

### Step 5: Present Summary

Print a concise terminal summary:

- Framework(s) detected and their boundaries
- Counts: critical / high / medium / low gaps
- Top 3 most important findings
- Path to the full report
- Next step instruction: open the HTML report in a browser, check the boxes for gaps to address, then run `/djt-test-coverage --apply <report-path>`

---

## Phase 2 — Apply (`--apply` flag)

Triggered by: `/djt-test-coverage --apply .agents/output/coverage/<report>.html`

### Step 1: Re-read the Report

Read the specified report file. Collect all checked items (`- [x]`). If no items are checked, tell the user and stop.

### Step 2: Branch

Create a new git branch: `test/coverage-<scope>-<YYYY-MM-DD>`.

### Step 3: Implement Checked Tests

For each checked item:

1. Identify the source file and the specific gap described.
2. Locate or create the test file following the project's naming and location convention.
3. Write the minimal test that covers the described gap — no extra refactoring, no extra tests beyond what was checked.
4. Follow the project's existing test patterns (describe blocks, assertion style, mocking approach).

After implementing all checked items:

- **STOP** and prompt the user to run the test suite and confirm all new tests pass.
- Do not commit until the user confirms.

### Step 4: Commit

After user confirmation:

- Commit with message: `test: add coverage for <scope> — <N> gaps addressed`
- Commit body: list each covered gap as a bullet.

### Step 5: Report

Print a summary of what was implemented and remind the user to open a PR if needed.
