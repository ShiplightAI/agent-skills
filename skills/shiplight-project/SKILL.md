---
name: shiplight-project
description: "Load Shiplight test project guides and context. Use when working on a Shiplight E2E test project — creating tests, updating tests, fixing test failures, or managing auth fixtures. "
---

# Shiplight Project

This is a Shiplight E2E test project.

## Project Layout

```
specs/tests/      one Markdown spec per executable test
tests/            executable Shiplight YAML tests
environments/     environment files (name → base URL)
auth/             auth fixture TypeScript files, if any
templates/        reusable YAML statement groups, if any
functions/        TypeScript helper functions, if any
files/            fixture files, if any
test-results/     generated runtime artifacts (do not edit)
shiplight-report/ generated reports (do not edit)
.shiplight/       local Shiplight state (do not edit)
```

## Edit Contract

Agents may edit:

- `specs/tests/**/*.md`
- `tests/**/*.test.yaml`
- `environments/**/*.env.yaml`
- `auth/**/*.auth.ts`
- `templates/**/*.tmpl.yaml`
- `functions/**/*.func.ts`
- `files/**`
- `playwright.config.ts` — only when changing project-level runtime behavior
- `package.json` — only when changing commands or dependencies

Agents must not edit:

- `**/*.yaml.spec.ts`
- `test-results/**`
- `shiplight-report/**`
- `.shiplight/**`
- `node_modules/**`
- `.env`
- `package-lock.json` — unless a dependency change requires it

## Commands

```sh
npm test              # run all tests
npm run test:headed   # run all tests headed
```

Use the narrowest relevant command when debugging a specific test.

## Ground Truth

When sources disagree, this precedence applies:

1. Explicit user instruction
2. Test spec in `specs/tests/`
3. Existing test `goal`, step `intent`, and `VERIFY` assertions
4. Current app behavior
5. Agent docs in this project
6. Agent inference

If current app behavior conflicts with the test spec or test goal, report the mismatch — do not silently rewrite the test.

## On every invocation

1. Read `references/knowledge.md` — how to read and write knowledge notes.
2. Check `knowledge/` in the current working directory for runtime knowledge notes left by previous agents. Read any files relevant to your task.

## Task-specific guides

Read the guide(s) that match your task before proceeding:

| Task | Guides |
|------|--------|
| Writing a new test | `references/creating-tests.md`, `references/test-design-guide.md`, `references/test-implementation-guide.md` |
| Updating or fixing a test | `references/updating-tests.md`, `references/test-design-guide.md`, `references/test-implementation-guide.md` |
| Auth fixtures and login | `references/auth.md` |

## After reading

Confirm to the user which guides you loaded, then proceed with the task.
