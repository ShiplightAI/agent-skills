# Updating Tests

Use this workflow when changing, debugging, or repairing existing Shiplight YAML tests.

## Before Editing

1. Read the matching spec under `specs/tests/`, if one exists.
2. Read the YAML test `goal`, step `intent`s, and `VERIFY` assertions.
3. Scan related tests for the same page or feature. Borrow working locators and patterns instead of guessing.
4. Identify the reason for the update:
   - Locator drift: the UI changed but intended behavior did not.
   - Product change: intended behavior changed intentionally.
   - Test bug: the implementation was wrong.
   - Coverage gap: new assertions or journeys are needed.

## Intended Behavior Has Not Changed

Update only the implementation: locators, waits, setup, or assertions needed to restore the behavior described by the spec.

Do not:

- Delete assertions to make a test pass.
- Skip required steps.
- Reduce coverage to avoid a failure.

If current app behavior conflicts with the spec or test goal, report the mismatch.

## Intended Behavior Has Changed

If the product changed intentionally:

1. Update the spec first.
2. Then update YAML to match the updated spec.
3. Mark the spec `Implemented` after completing and verifying the change.

## Files Not To Edit

Do not edit generated or local-state files:

- `**/*.yaml.spec.ts`
- `test-results/**`
- `shiplight-report/**`
- `.shiplight/**`
- `node_modules/**`

These files may be useful for debugging but must not become the source of test intent.

## Test Data

Prefer unique data per run when a test creates records. Do not depend on shared mutable state.

If a test requires specific accounts, fixtures, or pre-existing records, document those dependencies in the spec.

## Reporting After Updates

After completing update work, report:

- Files created or changed
- Behavior covered
- Command run and pass/fail result
- Any product/spec mismatch or unresolved blocker
