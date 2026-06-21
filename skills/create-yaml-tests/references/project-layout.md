# Project Layout

Shiplight test projects use committed specs and YAML tests, plus local generated state. All paths below are relative to the Shiplight test project root.

```text
specs/context.md       project-level app, risk, data, and target-deployment context
specs/tests/           Markdown specs, each covering a feature or journey group
tests/                 executable Shiplight YAML tests
playwright.config.ts   project-level Playwright config, shared auth, and runtime defaults
auth.setup.ts          shared-account Playwright auth setup, if needed
auth/                  optional auth helpers or per-test login scripts
templates/             reusable YAML statement groups, if any
helpers/               TypeScript helper functions, if any
fixtures/              fixture files, if any
knowledge/             durable notes discovered by agents
test-results/          generated runtime artifacts; do not edit
shiplight-report/      generated reports; do not edit
.shiplight/            local Shiplight state; do not edit
```

## Scaffold a Project
Scaffold the Shiplight project files. Call the `scaffold_project` MCP tool against the test-project root, even if the directory already contains a repo, `.env`, or its own `package.json`. The tool writes any missing files and reports the rest under `files_needing_agent_merge` — see "Handling scaffold_project conflicts" below.

Do not pre-create empty directories. Create them only when you have content to place in them (e.g. do not create `templates/` until you have a template to write).

### Handling scaffold_project conflicts

When the target directory is empty, `scaffold_project` writes all files and `files_needing_agent_merge` is empty — proceed normally.

When the user already had files (common when adding Shiplight to an existing repo), `files_needing_agent_merge` contains one entry per conflict. For each entry:

1. Read the file at `abs_path` with your Read tool.
2. Apply the change described by `merge_strategy` and `instructions`, using the supplied `template` (and `lines_to_ensure` / `merge_key` when present) as the source of truth.
3. Write the merged result back with Edit (preferred) or Write — never delete the user's existing content.

`merge_strategy` values you may see:

| Strategy | Typical file | What to do |
|----------|--------------|------------|
| `json_merge_deps_and_scripts` | `package.json` | Add missing deps + `test`/`test:headed` scripts. Do not change `name`, `version`, or other fields. Ask before flipping `type` to `"module"`. |
| `append_missing_lines` | `.gitignore` | For each line in `lines_to_ensure`, append it if not already present. Group under a `# Shiplight` comment block. |
| `json_merge_under_key` | `.mcp.json` | Add the template's entries under `merge_key` (e.g. `mcpServers`). Do not overwrite a server name the user already has. |
| `append_missing_env_keys` | `.env.example` | For each `KEY=` line in the template, append it (preserving commented form) only if `KEY` is not already mentioned. |
| `review_and_decide` | `playwright.config.ts` | Show the user the template and ask whether to replace, merge `...shiplightConfig()`, or leave alone. Do not modify without confirmation. |

Resolve every entry before moving on to `npm install`. A skipped merge usually leaves the project unable to run Shiplight tests.

## Edit Contract

Agents may edit:

- `specs/context.md`
- `specs/tests/**/*.md`
- `tests/**/*.test.yaml`
- `playwright.config.ts`
- `auth.setup.ts`
- `*.login.ts`
- `auth/**/*.login.ts`
- existing project auth helpers referenced by `playwright.config.ts` or YAML `use.auth`
- `templates/**/*.tmpl.yaml`
- `helpers/**/*.func.ts`
- `fixtures/**`
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
