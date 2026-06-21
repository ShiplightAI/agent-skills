---
name: review
description: "Review orchestrator and single entry point for all application reviews. Triage what needs reviewing, then run the right domains: security (OWASP, auth, headers, supply chain), privacy (PII, tracking, consent, GDPR/CCPA), compliance (HIPAA, SOC 2, PCI-DSS, GDPR), design (responsive, accessibility, typography, i18n), resilience (error handling, degradation, API contracts), performance (Core Web Vitals, bundles, runtime), SEO (meta, structured data, crawlability), and GEO (AI citation readiness, llms.txt, entity clarity). Use for pre-launch readiness, post-incident planning, or any 'review my app for X' request."
---

# Review Orchestrator

The single entry point for application reviews. It triages what matters, then
runs one or more domain reviews and merges them into a unified report. Each
domain lives in `references/<domain>.md` and is loaded only when selected.

## When to use

- User wants a review but isn't sure which kind
- Pre-launch readiness assessment
- Post-incident review planning
- A targeted request for one domain ("check my app's security", "review SEO")

## Modes

- **Triage** (default, `/review`) — ask context questions, recommend a plan, run it.
- **Full suite** (`/review --all`) — run every applicable domain.
- **Targeted** (`/review <domain>`) — jump straight into one domain, skipping
  triage. E.g. `/review security`, `/review seo`. Accepts an optional depth flag
  (`--quick` / `--thorough`).

## Domains

Each row maps to a reference file. Load the file only when the domain is selected.

| Domain | Reference | Run it when… (trigger signals) |
|--------|-----------|-------------------------------|
| security | `references/security.md` | auth/login changes, sensitive data, OWASP, headers/CORS/CSP, supply chain |
| privacy | `references/privacy.md` | collects PII, tracking/analytics, consent banners, GDPR/CCPA |
| compliance | `references/compliance.md` | regulated industry, audit prep, HIPAA/SOC 2/PCI-DSS/GDPR, payments or health data |
| design | `references/design.md` | UI shipping without a designer, responsive, accessibility, typography, i18n |
| resilience | `references/resilience.md` | error handling, network/API failures, empty/edge states, degradation |
| performance | `references/performance.md` | slow pages, Core Web Vitals, bundle size, runtime/render perf |
| seo | `references/seo.md` | public site, meta tags, structured data, crawlability, sitemaps |
| geo | `references/geo.md` | discovered via AI assistants, LLM citation readiness, llms.txt, entity clarity |

Shared conventions (phases, scoring, confidence, severity, output paths) live in
`references/report-format.md` — every domain follows them.

## Steps

### 1. Gather context

- Read the project: tech stack, framework, `package.json`, routes, components.
- Check `git diff` for recent changes.
- Look for existing reports in `shiplight/reports/`.
- Auto-detect compliance markers (HIPAA/PHI, PCI/payment fields, GDPR/cookie consent).

If invoked as `/review <domain>`, skip to step 4 for that domain.

### 2. Ask targeted questions (max 4)

One at a time, with auto-detected defaults:

1. **What type of application?** (SaaS, healthcare, fintech, e-commerce, internal tool, marketing site, API-only)
2. **What triggered this review?** (pre-launch, new feature, dependency update, security incident, audit prep, routine)
3. **Any compliance requirements?** (none, HIPAA, SOC2, PCI-DSS, GDPR, multiple) — auto-detect from codebase
4. **Specific concerns?** (open-ended, optional)

### 3. Generate review plan

Categorize each applicable domain as **CRITICAL** (must run), **RECOMMENDED**
(meaningful value), or **OPTIONAL** (nice to have), with estimated depth
(quick / standard / thorough).

**SEO vs GEO prioritization by product type:**

| Product type | SEO | GEO |
|---|---|---|
| Developer tools, API products, SaaS | RECOMMENDED | CRITICAL |
| E-commerce, local business, marketplace | CRITICAL | OPTIONAL |
| Content/media, documentation, blog | CRITICAL | CRITICAL |
| Internal tools | — | — |

Present a decision matrix:

| Review | Priority | Rationale | Depth |
|--------|----------|-----------|-------|
| security | CRITICAL | New auth feature + SaaS app | thorough |
| privacy | CRITICAL | Handles user PII, GDPR applies | standard |
| … | | | |

### 4. Execute

Ask: "Run all CRITICAL reviews now? [Y/n] Or pick specific ones."

For each selected domain, **read `references/<domain>.md` and follow its five
phases**, applying `references/report-format.md` for scoring, severity, and
output paths. Run domains sequentially; show a brief summary after each before
moving on.

### 5. Unified report

After the selected domains complete, merge their per-domain reports into one,
saved to `shiplight/reports/review-{date}.md`:

- Overall readiness score (0–10) and per-domain scores
- Top 5 findings across all domains, by severity
- Regression test summary (total YAML tests generated, in `shiplight/tests/`)

## Tips

- Run `/review` before every major launch.
- `/review <domain>` is the fast path when you already know what you need.
- Reports accumulate in `shiplight/reports/` — the orchestrator can show trends.
- YAML regression tests from reviews accumulate in `shiplight/tests/`.
