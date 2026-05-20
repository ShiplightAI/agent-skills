# New Tests

Use this workflow when adding new Shiplight YAML tests.

## 1. Determine The Environment

Every test targets a named environment. Environments are defined in `environments/*.env.yaml`.

If a matching environment file exists, reuse it. If not, create one:

```yaml
name: staging
url: https://staging.example.com
```

The `url` field becomes the YAML test `base_url`.

If the target environment is ambiguous, ask the user. Do not silently switch environments to make a test pass.

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

1. List available accounts from the environment YAML `accounts` key.
2. Ask the user which account or role to use if it is not obvious.
3. If a new account is needed, add the username and env var references to the environment YAML. Do not ask for or commit the password value.
4. Check `auth/` for an existing login module. Reuse it when possible; create one only when needed.

See `auth.md`.

## 3. Write Or Update The Spec

Create or update the relevant spec under `specs/tests/`.

Specs describe feature or journey-group confidence. A spec can map to multiple smaller YAML tests.

Use `references/test-spec-template.md` for new specs.

The spec must include:

- Goal
- User roles
- Environment
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

1. Open a Shiplight MCP browser session at the target environment.
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

Use the url from the matching environment file as `base_url`.

If the test requires auth, add `use.account`. See `auth.md`.

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
