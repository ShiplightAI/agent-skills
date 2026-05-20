# Test Spec: <Name>

## Status

Draft

Allowed values: Draft, Ready, Implemented.

## Goal

Describe the user-visible behavior this test should protect.

## User Role

Describe the user, account type, permission level, or auth state required.

## Starting Point

- Environment: <environment name from environments/*.env.yaml, not a URL>
- Auth: <none, anonymous visitor OR logged in as role/account fixture>

## Preconditions

- List required setup, existing account state, feature flags, or app state before the test starts.
- Keep concrete records, IDs, names, and generated values in Test Data.

## Test Data

- List concrete records, IDs, names, routes, input values, fixture files, generated data, and uniqueness requirements the executable test depends on.
- If data must already exist, include enough detail to locate it deterministically.
- If data is created during the test, describe how it should be named.

## Steps

1. Start from the specified page or state.
2. Perform the main user action.
3. Continue through the workflow until the expected result is observable.

## Expected Result

- State the final success condition in user-visible terms.

## Assertions

- List the concrete user-visible checks the executable test should make.

## Cleanup

- List any state the test must remove, reset, or restore after execution.
- If cleanup is not needed, write: None.

## Out Of Scope

- List related behavior this test should not cover.

## Notes

- Add non-obvious assumptions, known product constraints, or open questions.

## Implementation

- Test file:
