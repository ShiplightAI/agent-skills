# Shiplight Agent Skills

AI-powered test automation skills — ship with confidence by letting your coding agent verify, test, and iterate autonomously.

Single source of truth for every agent (Claude Code, Cursor, Codex, and [40+ more](https://github.com/vercel-labs/skills#supported-agents)). Install skills with [`skills`](https://www.npmjs.com/package/skills) and the MCP server with [`add-mcp`](https://www.npmjs.com/package/add-mcp).

## Prerequisite

All skills depend on the [Shiplight MCP server](https://www.shiplight.ai). Install it once for your agent (see [Install](#install) below), or run:

```bash
npx add-mcp "npx -y @shiplightai/mcp@latest" -n shiplight --env PWDEBUG=console
```

## Skills

### Essentials

| Skill | Purpose |
|-------|---------|
| `/verify` | Visually confirm UI changes in the browser after a code change |
| `/create-yaml-tests` | Spec-driven E2E test creation: plan, scaffold, and write deterministic YAML tests by walking through the app |
| `/create-agent-tests` | Author and run coding-agent-driven Markdown test cases against a live environment (browser, API, DB, logs) with auditable PASS/FAIL reports |
| `/triage` | Reproduce failing E2E tests, diagnose root causes, fix YAML, and report app bugs |
| `/cloud` | Sync local tests with Shiplight cloud for scheduled runs, team collaboration (subscription required) |

### Test coverage

| Skill | Purpose |
|-------|---------|
| `/test-coverage` | After a feature/PR, pick the testing strategy and drive the producers to write comprehensive tests; record what was tested and by what type |

### Review helpers

`/review` is the single entry point. It triages your app and runs the right domain reviews, or jump straight to one with `/review <domain>` (e.g. `/review security`).

| Skill | Purpose |
|-------|---------|
| `/review` | Orchestrator + all review domains: **security** (OWASP, auth, injection, access control, supply chain), **privacy** (PII, consent, tracking, data flows, user rights), **compliance** (HIPAA, SOC 2, PCI-DSS, GDPR), **design** (visual, responsive, accessibility, typography, i18n), **resilience** (error handling, degradation, edge states, API contracts), **performance** (Core Web Vitals, bundles, runtime), **SEO** (meta, structured data, crawlability), **GEO** (AI citation readiness, llms.txt, entity clarity) |

## Install

### Claude Code

```bash
npx -y skills add ShiplightAI/agent-skills -a claude-code -y && \
npx -y add-mcp "npx -y @shiplightai/mcp@latest" -n shiplight --env PWDEBUG=console -a claude-code -y
```

### Cursor

```bash
npx -y skills add ShiplightAI/agent-skills -a cursor -y && \
npx -y add-mcp "npx -y @shiplightai/mcp@latest" -n shiplight --env PWDEBUG=console -a cursor -y
```

Cursor disables newly-added MCP servers by default. Enable it: **Cursor → Settings… → Cursor Settings → Tools & MCPs → Installed MCP Servers → shiplight (Disabled)** — toggle the switch to enable.

### Codex

```bash
npx -y skills add ShiplightAI/agent-skills -a codex -y && \
npx -y add-mcp "npx -y @shiplightai/mcp@latest" -n shiplight --env PWDEBUG=console -a codex -y
```

### Any other agent

Pick from [supported agents](https://github.com/vercel-labs/skills#supported-agents) and swap the `-a` flag. Use `--all` to install to every detected agent, or `-g` for a user-level (global) install.

```bash
npx skills add ShiplightAI/agent-skills --all
```

Restart your agent after installing.

## Install individual skills

```bash
npx skills add ShiplightAI/agent-skills --skill verify --skill triage -a claude-code
```

List all skills in this repo:

```bash
npx skills add ShiplightAI/agent-skills --list
```

## Update

```bash
npx skills update
```

The `/verify` and `/create-yaml-tests` skills also include an opportunistic daily update check. When a coding agent uses one of those skills, the skill asks the agent to use `.shiplight-agent-skills-last-update` as the project-local attempt timestamp. On first use, if the file does not exist yet, the agent should create it and skip the update so a newly installed project does not pay for a second install. After that, the agent should run `npx -y skills@latest update -y` at most once every 24 hours. Treat this file as local cache and do not commit it.

## Links

- [Shiplight](https://www.shiplight.ai)
- [Documentation](https://docs.shiplight.ai/getting-started/quick-start.html)
- [`skills` CLI](https://github.com/vercel-labs/skills)
- [`add-mcp` CLI](https://github.com/neondatabase/add-mcp)
