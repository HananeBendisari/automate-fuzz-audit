# Audit-Level Fuzz Testing Suite for `Automate.sol`

This folder contains a modular fuzzing suite targeting the `Automate.sol` contract, inspired by audit-level testing methodology.

The goal is not to achieve 100% green test runs, but to simulate adversarial behavior and validate protocol resilience under unexpected input conditions.

## Covered Functions

- `createTask(...)`
- `cancelTask(...)`
- `exec(...)`
- `setModule(...)`
- `getTaskId(...)`

## Test Strategy

Each fuzz test is designed to target one function with:

- `vm.assume(...)` to constrain input ranges
- `expectRevert(...)` to validate proper failure handling
- `recordLogs()` to verify event emission
- Invariant checks (e.g., taskId uniqueness, task retention on failed exec)
- Mocks for modules, fee tokens, and executors

Tests are structured with clarity in mind:
- One contract per fuzz target (`FuzzExecTest.t.sol`, etc.)
- Explicit `@dev AUDIT:` annotations on test functions
- Severity categorization (`Critical`, `Medium`, `Informational`)

## Known Limitations

Some tests are expected to fail or skip due to:

- Access control (`onlyProxyAdmin`, `onlyGelato`)
- Uninitialized module configs
- Missing upstream deployment context

These are **intentional** and reflect the goal of testing the system's reaction to edge-case inputs and invalid states.

## Status

This suite is still in progress. It will be extended or adapted as the protocol evolves or as test environments become more robust.

