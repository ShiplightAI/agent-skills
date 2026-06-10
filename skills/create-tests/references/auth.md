# Auth

This guide explains the preferred authentication patterns for local Shiplight test projects and when to use each one.

These are recommended defaults, not the only possible Playwright auth approaches.
Use them unless the project already has a different Playwright-native auth setup
that works through normal Playwright config, setup projects, `use`, or
`storageState`.

## Does A Test Need Auth?

Before writing a test, determine whether it requires an authenticated session:

- Does the starting page redirect anonymous visitors to login?
- Do the user actions require an account?

If unclear, infer from app behavior or ask the user. Document the answer in the spec before writing YAML.

## Choose The Auth Pattern

Start with one of these two approaches:

### Shared Account (Most Common)

Use this when the whole run can share one identity. Prefer this pattern unless tests in the same run must use different users.

Create a Playwright setup project that logs in once, saves `storageState`, and make the main test project depend on it.

Example:

```ts
// auth.setup.ts
import { test as setup } from "@playwright/test";

setup("login", async ({ page }) => {
  await page.goto("/login");
  await page.getByLabel("Email").fill(process.env.USERNAME!);
  await page.getByLabel("Password").fill(process.env.PASSWORD!);
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.waitForURL("/dashboard");
  await page.context().storageState({ path: ".auth/default.json" });
});
```

```ts
// playwright.config.ts
export default defineConfig({
  ...shiplightConfig(),
  projects: [
    { name: "auth", testMatch: "auth.setup.ts" },
    {
      name: "default",
      dependencies: ["auth"],
      use: {
        baseURL: "https://staging.example.com",
        storageState: ".auth/default.json",
      },
    },
  ],
});
```

Key points:

- Tests do not declare an auth block when shared auth is configured; they inherit the authenticated `storageState`.
- This is the default recommendation for one-account suites.
- If the shared account can vary by environment or role, select it at runtime with env vars rather than creating per-test auth blocks.

### Per-Test Auth (Advanced)

Use this only when different tests in the same run must log in as different users.

Each test declares its auth script and optional args inline. The auth script exports `login(args)`, performs the login flow, manages `storageState` caching, and returns the path to a storage-state JSON file.

Example:

```ts
// auth.login.ts
import { chromium } from "@playwright/test";
import * as fs from "fs";
import * as path from "path";

export async function login(args: Record<string, unknown>): Promise<string> {
  const stateFile = path.join(".auth", `${args.username}.json`);

  if (fs.existsSync(stateFile)) return stateFile;

  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.goto("/login");
  await page.getByLabel("Email").fill(args.username as string);
  await page.getByLabel("Password").fill(args.password as string);
  await page.getByRole("button", { name: "Sign in" }).click();
  await page.waitForURL("/dashboard");

  fs.mkdirSync(path.dirname(stateFile), { recursive: true });
  await context.storageState({ path: stateFile, indexedDB: true });
  await browser.close();

  return stateFile;
}
```

```yaml
use:
  account:
    auth: ./auth.login.ts
    args:
      username: admin@example.com
      password: "{{ADMIN_PASSWORD}}"
goal: Admin can manage users
statements:
  - URL: /admin/users
  - VERIFY: User management page is visible
```

Key points:

- The `args` object is passed directly to `login(args)`.
- The auth script can accept any fields the login flow needs, such as usernames, passwords, TOTP secrets, org IDs, or API tokens.
- The auth script owns caching and expiration policy for `.auth/*`.
- Tests without `use.auth` run with the default context. If shared auth is configured, they inherit that `storageState`; otherwise they run unauthenticated.

## File Placement

Do not assume auth files must live under `auth/`.

Common choices:

- `playwright.config.ts` at the project root when shared auth configures setup projects or default `storageState`
- `auth.setup.ts` at the project root for shared-account setup
- `auth.login.ts` at the project root for per-test auth
- `auth/*.login.ts` when the project has several reusable auth helpers

Reuse existing auth files before creating new ones.

## Account And Secret Documentation

Store durable account-role facts in `specs/context.md` or `knowledge/`:

- Which auth pattern or Playwright-native auth setup the project uses
- Which roles exist
- Which tests require which roles
- Which env vars must be present in `.env`

Do not commit actual passwords, API keys, tokens, cookies, or one-time codes.

## Secrets Policy

Never commit real credentials to specs, tests, fixtures, or docs.

Credentials belong in `.env`. Specs, notes, config, and YAML may reference env vars or templated secret placeholders, but not raw secret values.
