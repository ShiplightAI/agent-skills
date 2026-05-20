# Updating Tests

Use this workflow when changing, debugging, or repairing existing tests.

## Before Editing

1. Read the matching spec under `specs/tests/`, if one exists.
2. Read the YAML test `goal`, step `intent`s, and `VERIFY` assertions.
3. Scan other tests in `tests/` that cover the same page or feature — borrow working locators and patterns from them rather than guessing.
4. Identify the reason for the update:
   - **Locator drift**: the UI changed but the intended behavior did not.
   - **Product change**: the intended behavior changed intentionally.
   - **Test bug**: the implementation was wrong to begin with.
   - **Coverage gap**: new assertions need to be added.

## When the Intended Behavior Has Not Changed

Update only the implementation — locators, waits, or setup — to restore the behavior described by the spec.

Do not:

- Delete assertions to make a test pass.
- Skip steps the spec requires.
- Reduce coverage to avoid a failure.

If current app behavior conflicts with the spec or test goal, **report the mismatch** instead of rewriting the test around the current UI.

## When the Intended Behavior Has Changed

If the product has changed intentionally:

1. Update the spec first.
2. Then update the YAML test to match the updated spec.

Mark the spec `Needs Update` before starting. Mark it `Implemented` after completing and verifying.

## Files Not to Edit

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

- Files created or changed.
- Behavior covered.
- Command run and pass/fail result.
- Any product/spec mismatch or unresolved blocker.