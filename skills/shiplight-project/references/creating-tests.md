# Creating Tests

When asked to create a test, follow this workflow in order. Do not skip steps.

## 1. Determine the Environment

Every test must target a specific named environment. Environments are defined in `environments/*.env.yaml`.

### Find or create the environment file

Check `environments/` for an existing file that matches the target deployment (e.g., `prod`, `staging`, `local`). If one does not exist, create it:

```yaml
name: staging
url: https://staging.example.com
```

The `url` field becomes the `base_url` in the YAML test.

### Clarify if ambiguous

If the target environment is not obvious from context, ask the user before proceeding.

Do not silently switch environments to make a test pass.

## 2. Determine Auth

Decide whether the test requires authentication before writing any test steps.

Ask yourself:

- Does the starting page redirect anonymous visitors to login?
- Do the actions in the test require an authenticated user?

If unclear, infer from app behavior or ask the user.

### If auth is not required

No account or auth fixture is needed. Note this in the spec when you write it:

```md
- Auth: none, anonymous visitor
```

### If auth is required

1. List the available accounts from the environment YAML file (`accounts` key) and ask the user which account to use.
2. If a new account is needed, ask the user a direct question: "What is the username for this account?" Add the account to the environment YAML with the username stored directly and env var references only for the password and any other security-sensitive fields. Tell the user which variables to add to `.env`.
3. Check `auth/` for an existing fixture for that account. If none exists, create one.

See `auth.md` for account definition format, env var naming convention, and how to write auth fixtures.

## 3. Write the Spec

Now that environment and auth are resolved, create or locate a spec under `specs/tests/`. The spec is the source of truth for what the test should prove.

If no spec exists for the requested behavior, create one using the template at `.claude/test-spec-template.md`.

The spec must include:

- **Goal**: the user-visible behavior the test protects
- **Environment**: the environment name determined in step 1
- **Auth**: the account reference determined in step 2
- **Expected result**: what success looks like

```md
## Starting Point

- Environment: prod
- Auth: logged in as workspace member (prod/workspace-member)
```

Use the environment name (e.g., `prod`), not the raw URL.

Mark the spec `Draft` if any fields are still unresolved. Mark it `Ready` when the YAML test can be implemented without further questions. Do not proceed to step 4 until the spec is `Ready`.

## 4. Walk the App and Implement the YAML Test

Once the spec is `Ready`:

1. Open a browser session and walk through the exact flow described in the spec. Capture accurate locators for every interactive element.
2. Create the YAML test under `tests/` using those locators.

```yaml
# Spec: specs/tests/feature-name.md
goal: User can complete the target workflow
base_url: https://staging.example.com

statements:
  - URL: /path
  ...
```

- Use the `url` from the matching `environments/*.env.yaml` file as `base_url`.
- If the test requires auth, add `storage_state` pointing to the fixture's saved session file. See `auth.md`.

Do not write statements from memory — always walk the app first.

## 5. Validate and Run

1. Validate the YAML using the `validate_yaml_test` tool. If it is rejected for too many draft statements, return to step 4 and capture more locators.
2. Run the test with: `npx playwright test tests/<name>.test.yaml`
3. If the test fails because the implementation violates the spec, fix the test.
4. If the test fails because the app behavior differs from the spec, report the mismatch — do not rewrite the spec to match broken behavior.

## 6. Update the Spec

Do not close the task until this step is complete.

- Update the spec status to `Implemented`.
- Add the test file path to the `Implementation` section of the spec.