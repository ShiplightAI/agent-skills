# New Tests

Use this workflow when adding new Shiplight YAML tests.

## 1. Determine The Target URL

Every test targets a specific deployment or base URL.

If a matching target URL is already documented in nearby tests, `specs/context.md`, or `knowledge/`, reuse it. If not, record it in the relevant spec or `specs/context.md` before writing YAML:

```yaml
base_url: https://staging.example.com
```

The confirmed URL becomes the YAML test `base_url`.

If the target deployment is ambiguous, ask the user. Do not silently switch URLs to make a test pass.

## 2. Determine Auth

Decide whether the test requires authentication before writing test steps.

Ask:

- Does the starting page redirect anonymous visitors to login?
- Do the actions in the test require an authenticated user?

If auth is not required, document this in the spec:

```md
- Auth: none, anonymous visitor
```

If auth is required:

1. Check whether the project already has a working Playwright-native auth setup. Reuse it when it matches the identities the tests need.
2. If the project does not already have a suitable auth setup, prefer shared auth unless different tests in one run need different identities.
3. List available roles, accounts, and required env vars from `specs/context.md`, `knowledge/`, relevant specs, or existing auth files.
4. Ask the user which account or role to use if it is not obvious.
5. If shared auth is appropriate, check for an existing `auth.setup.ts` and matching `playwright.config.ts` setup. Reuse or extend it when possible.
6. If per-test auth is required, check for an existing `*.login.ts` auth script. Reuse it when possible; create one only when needed.
7. If a new account or secret reference is needed, record the username or role plus env var names in `specs/context.md` or `knowledge/`. Do not ask for or commit the password value.

See `auth.md`.

## 3. Write Or Update The Spec

Create or update the relevant spec under `specs/tests/`.

Specs describe feature or journey-group confidence. A spec can map to multiple smaller YAML tests.

Use `references/test-spec-template.md` for new specs.

The spec must include:

- Goal
- User roles
- Base URL
- Auth
- Journeys or variants
- Expected results
- Assertions
- Test data
- Cleanup
- Implementation plan

Mark the spec `Draft` if fields are unresolved. Mark it `Ready` when YAML implementation can proceed without further product questions.

Do not proceed to implementation while the relevant spec is `Draft`, unless the user explicitly asks to skip specs.

## 4. Walk The App And Implement YAML

Once the spec is ready:

1. Open a Shiplight MCP browser session at the target URL.
2. Walk through the exact flow described in the spec.
3. Capture locators for interactive elements.
4. Create focused YAML tests under `tests/`.

Example:

```yaml
# Spec: specs/tests/login.md
goal: Existing user can sign in with a valid password
base_url: https://staging.example.com

statements:
  - URL: /login
```

Use the confirmed target URL as `base_url`.

If the project uses shared auth, tests usually need no auth block. If the test requires per-test auth, add `use.auth` and optional `args`. If the project already has another Playwright-native auth pattern wired through config or `storageState`, follow that existing pattern instead of rewriting it just to match the examples. See `auth.md`.

Do not write statements from memory. Always walk the app first.

## 5. Validate And Run

1. Validate the YAML with the `validate_yaml_test` mcp tool.
2. Run the narrowest relevant command, usually one test file.
3. If validation rejects too many draft statements, return to the browser and capture more locators.
4. If the test fails because implementation violates the spec, fix the test.
5. If app behavior differs from the spec, report the mismatch.

## 6. Update The Spec

Before closing the task:

- Mark implemented coverage in the relevant spec.
- Add or update the YAML test file paths.
- Document skipped journeys, known gaps, and product/spec mismatches.
