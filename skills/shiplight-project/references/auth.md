# Auth

This guide explains how to reason about authentication, how accounts are defined in environment files, and how to write auth login modules for tests that require login.

## Does a Test Need Auth?

Before writing a test, determine whether it requires an authenticated session:

- Does the starting page redirect anonymous visitors to login?
- Do the user actions the test performs require an account?

If unclear, infer from context or ask the user. Document the answer in the spec before writing any YAML.

## Accounts in Environment Files

Accounts are defined inside the environment YAML file, not in separate files. Each account is a list entry with:

- `username`: the actual account email or username (not sensitive, committed as-is)
- `password`: the name of the env var holding the password
- `2fa_secret`: (optional) the name of the env var holding the 2FA secret

```yaml
name: prod
url: https://prod.example.com

accounts:
  - username: member@example.com
    password: PROD_MEMBER_PASSWORD
  - username: admin@example.com
    password: PROD_ADMIN_PASSWORD
    2fa_secret: PROD_ADMIN_2FA_SECRET
```

### Adding a new account

When a test needs an account that is not yet in the environment YAML:

1. Infer or clarify the account type needed (e.g., workspace member, admin). Do not ask the user for the password or 2FA secret.
2. Add the account entry to the environment YAML with the username and well-named env var references.
3. Tell the user which variables to add to `.env`.

Example message to user:

> Added an account to `environments/prod.env.yaml`. Please add the following to your `.env`:
>
> ```
> PROD_MEMBER_PASSWORD=
> ```

## Auth Login Modules

An auth login module is a TypeScript file under `auth/` that exports a `login(args)` function. It performs the login flow, caches the resulting browser session state under `.auth/`, and returns the path to the state file. Session state is cached for 1 hour; subsequent calls within that window skip the login and return the cached path immediately.

File naming: `auth/<app-name>.login.ts`

Example: `auth/staging.login.ts`

### When to create a new login module

**Always read `auth/` before creating anything.** If a login module already exists for the same environment, reuse it — pass different `username`/`password` args for different accounts. 

Create a new module only when no module exists for the target environment.

### What a login module does

```ts
export async function login(args: Record<string, unknown> = {}): Promise<string> {
  const username = args.username as string;
  // args.password is the env var name; resolve it from process.env
  const rawPassword = args.password as string;
  const password = process.env[rawPassword] ?? rawPassword;
  // ...login flow...
  // returns path to cached .auth/<username>.json
}
```

Key points:
- `args.password` is the **name** of the env var (e.g. `STAGING_MEMBER_PASSWORD`), resolved via `process.env` inside the module. Never hardcode passwords.
- State files are written to `.auth/` (gitignored). The filename is derived from the username.
- The module caches state for 1 hour. If the cached file is fresh, login is skipped.

### Referencing a login module in a test

Use the `use.account` field in the YAML test:

```yaml
# Spec: specs/tests/files-list.md
goal: Workspace member can view files
base_url: https://staging.example.com
use:
  account:
    auth: auth/staging.login.ts
    args:
      username: member@example.com
      password: PROD_MEMBER_PASSWORD

statements:
  - URL: /files
  ...
```

`args.password` is the env var **name**, not the value. The login module resolves it from `process.env` at runtime.

Different tests can use different accounts by passing different `username` and `password` args — all using the same login module.

## Secrets Policy

Never commit real credentials to specs, tests, fixtures, environment files, or docs:

- passwords
- API keys
- tokens
- cookies
- one-time codes

Credentials belong in `.env`. Environment YAML files contain only env var names, not values. The `.env` file is gitignored and must not be edited unless the user explicitly asks.
