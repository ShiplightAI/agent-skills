# Project Layout

Shiplight test projects use committed specs and YAML tests, plus local generated state. All paths below are relative to the Shiplight test project root.

```text
specs/context.md       project-level app, risk, data, and environment context
specs/tests/           Markdown specs, each covering a feature or journey group
tests/                 executable Shiplight YAML tests
environments/          environment files, one per target deployment
auth/                  auth login modules, if needed
templates/             reusable YAML statement groups, if any
helpers/               TypeScript helper functions, if any
files/                 fixture files, if any
knowledge/             durable notes discovered by agents
test-results/          generated runtime artifacts; do not edit
shiplight-report/      generated reports; do not edit
.shiplight/            local Shiplight state; do not edit
```

## Edit Contract

Agents may edit:

- `specs/context.md`
- `specs/tests/**/*.md`
- `tests/**/*.test.yaml`
- `environments/**/*.env.yaml`
- `auth/**/*.login.ts`
- `templates/**/*.tmpl.yaml`
- `helpers/**/*.func.ts`
- `files/**`
- `playwright.config.ts` only when changing project-level runtime behavior
- `package.json` only when changing commands or dependencies

Agents must not edit:

- `**/*.yaml.spec.ts`
- `test-results/**`
- `shiplight-report/**`
- `.shiplight/**`
- `node_modules/**`
- `.env`, unless the user explicitly asks
- `package-lock.json`, unless a dependency change requires it

## Commands

Use the narrowest relevant command when debugging a specific test.

```sh
npm test
npm run test:headed
npx shiplight test --headed
```

If the project's `package.json` defines a more specific script, prefer that script.

## Source Of Truth

When sources disagree, this precedence applies:

1. Explicit user instruction
2. Feature or journey spec in `specs/tests/`
3. Existing YAML test `goal`, step `intent`, and `VERIFY` assertions
4. Current app behavior
5. Project context in `specs/context.md` and `knowledge/`
6. Agent docs in this skill
7. Agent inference

If app behavior conflicts with a spec or test goal, report the mismatch. Do not silently rewrite the test to match current behavior.
