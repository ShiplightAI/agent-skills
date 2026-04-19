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
| `/create_e2e_tests` | Spec-driven E2E test creation: plan, scaffold, and write YAML tests by walking through the app |
| `/triage` | Reproduce failing E2E tests, diagnose root causes, fix YAML, and report app bugs |
| `/cloud` | Sync local tests with Shiplight cloud for scheduled runs, team collaboration (subscription required) |

### Review helpers

| Skill | Purpose |
|-------|---------|
| `/review` | Orchestrator that recommends the right reviews for your app |
| `/design-review` | Visual quality, responsive, accessibility, typography, i18n |
| `/security-review` | OWASP Top 10, auth, injection, access control, supply chain |
| `/privacy-review` | PII leakage, consent, tracking, data flows, user rights |
| `/compliance-review` | HIPAA, SOC 2, PCI-DSS, GDPR technical requirements |
| `/resilience-review` | Error handling, graceful degradation, edge states, API contracts |
| `/performance-review` | Core Web Vitals, bundles, resources, runtime performance |
| `/seo-review` | Meta tags, structured data, crawlability, semantic HTML |
| `/geo-review` | AI citation readiness, llms.txt, entity clarity, AI search testing |

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

## Links

- [Shiplight](https://www.shiplight.ai)
- [Documentation](https://docs.shiplight.ai/getting-started/quick-start.html)
- [`skills` CLI](https://github.com/vercel-labs/skills)
- [`add-mcp` CLI](https://github.com/neondatabase/add-mcp)
