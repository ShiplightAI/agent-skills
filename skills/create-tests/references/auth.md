# Auth

This guide explains how to reason about authentication, define accounts, and write login modules.

## Does A Test Need Auth?

Before writing a test, determine whether it requires an authenticated session:

- Does the starting page redirect anonymous visitors to login?
- Do the user actions require an account?

If unclear, infer from app behavior or ask the user. Document the answer in the spec before writing YAML.

## Accounts In Environment Files

Accounts are defined inside `environments/*.env.yaml`.

Each account entry contains:

- `username`: actual account email or username; commit as-is if not sensitive
- `password`: env var name holding the password
- `2fa_secret`: optional env var name holding the 2FA secret

```yaml
name: staging
url: https://staging.example.com

accounts:
  - username: member@example.com
    password: STAGING_MEMBER_PASSWORD
  - username: admin@example.com
    password: STAGING_ADMIN_PASSWORD
    2fa_secret: STAGING_ADMIN_2FA_SECRET
```

## Adding A New Account

When a test needs an account not yet listed:

1. Infer or clarify the account type needed.
2. Add the account entry to the environment YAML with username and env var references.
3. Tell the user which variables to add to `.env`.

Do not ask for or commit actual passwords, API keys, tokens, cookies, or one-time codes.

## Auth Login Modules

An auth login module is a TypeScript file under `auth/` that exports a `login(args)` function. It performs login, caches browser session state under `.auth/`, and returns the state file path.

File naming:

```text
auth/<environment-or-app>.login.ts
```

Always read `auth/` before creating anything. If a login module already exists for the same app or environment, reuse it and pass different account args.

Create a new module only when no suitable module exists.

## Login Module Contract

```ts
export async function login(args: Record<string, unknown> = {}): Promise<string> {
  const username = args.username as string;
  const rawPassword = args.password as string;
  const password = process.env[rawPassword] ?? rawPassword;
  // perform login and return cached storage state path
}
```

Key points:

- `args.password` is the env var name, not the secret value.
- The module resolves secrets from `process.env`.
- State files are written under `.auth/`, which must be gitignored.
- Cached state should be reused when still fresh.

## Referencing Auth In YAML

Use `use.account`:

```yaml
# Spec: specs/tests/files.md
goal: Workspace member can view files
base_url: https://staging.example.com
use:
  account:
    auth: auth/staging.login.ts
    args:
      username: member@example.com
      password: STAGING_MEMBER_PASSWORD

statements:
  - URL: /files
```

Different tests can use different accounts by passing different args to the same login module.

## Secrets Policy

Never commit real credentials to specs, tests, fixtures, environment files, or docs.

Credentials belong in `.env`. Environment YAML files and YAML tests contain only env var names.
