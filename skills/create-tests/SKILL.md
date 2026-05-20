---
name: create-tests
description: "Spec-driven E2E test creation: plan what to test through structured discovery phases, then scaffold a local Shiplight test project and write YAML tests by walking through the app in a browser."
---

# Create Local YAML Tests

## Daily Skill Update Check

Before starting this skill's work, opportunistically refresh Shiplight skills at most once per day:

1. Check the timestamp file at `.shiplight/agent-skills-last-update` in the current project.
2. If the timestamp file is missing or older than 24 hours, run `npx -y skills@latest update -y`, then create/update the timestamp file even if the command fails. Treat `.shiplight/agent-skills-last-update` as local cache and do not commit it.
3. If the update command fails, continue with the currently installed skill and mention the failure briefly.

A spec-driven workflow that front-loads testing expertise through structured planning before any tests are written. Tests run with `npx shiplight test --headed` — no cloud infrastructure required.

## When to use

Use `/create-tests` when the user wants to:
- Create a new local test project from scratch
- Add YAML tests for a web application
- Set up authentication for a test project
- Plan what to test before writing tests

## Principles

1. **Always produce artifacts.** Every phase produces durable artifacts: Phases 1-3 write markdown specs, Phase 4 writes `.test.yaml` files, and Phase 5 reconciles the specs with the implemented tests. Artifacts clarify your own thinking, give the user something to review, and guide later phases. When the user provides detailed requirements, use them as source material — skip questions already answered, but still produce the artifact.

2. **Confirm before implementing.** Present the spec (Phase 2 checkpoint) for user confirmation before spending time on browser-walking and test writing. Echo back the outcomes and key scenarios to catch mismatches early.

3. **Each phase reads the previous phase's artifact.** Discover feeds Specify, Specify feeds Plan, Plan feeds Implement, Implement feeds Verify. If an artifact exists from a prior run, offer to reuse it.

4. **Escalate, don't loop.** When something fails or is ambiguous, report it and ask the user rather than retrying silently.

5. **Learn into `test-context.md`.** `test-context.md` is the living project memory for this test project. When the user provides durable product, domain, backend, account, data, environment, or testing-preference knowledge, fold it into `test-context.md` according to the Phase 1 section meanings before ending the session. Do not store raw secrets; store variable names, roles, access patterns, and setup instructions instead.

## Phase Overview

```
Phase 1: Discover  → test-context.md     (understand the app & user goals)
Phase 2: Specify   → test-spec.md        (define outcomes and detailed scenarios)
Phase 3: Plan      → test-plan.md        (prioritize, structure, per-test guidance)
Phase 4: Implement → *.test.yaml files   (setup project, write tests, run them)
Phase 5: Verify    → updated spec files  (coverage check, reconcile spec ↔ tests)
```

## Fast-Track

Check for existing artifacts before starting. The only way to skip artifact generation is if the user **explicitly** says so.

| Situation | Behavior |
|-----------|----------|
| User explicitly says "skip to implement" or "just write the tests" | Phase 4 only |
| Existing `test-specs/test-context.md` | Offer to reuse, skip Phase 1 |
| Existing `test-specs/test-strategy.md` | Old name for `test-context.md`; read it as context, but create/update `test-context.md` going forward |
| Existing `test-specs/test-spec.md` | Offer to reuse, skip Phases 1-2 |
| Existing `test-specs/test-plan.md` | Offer to reuse, skip to Phase 4 |

---

## Phase 1: Discover

**Goal:** Understand the application, the user's role, and what matters most to test.

**Output:** `<project>/test-specs/test-context.md`

`test-strategy.md` is the old name for `test-context.md`. If an existing project has `test-specs/test-strategy.md`, read it as the Phase 1 context artifact, but write new or updated context to `test-specs/test-context.md`.

### Steps

1. **Get project path** — ask where to create the test project (e.g., `./my-tests`). All artifacts and tests will live here. Create the `test-specs/` directory.

   If cloud MCP tools are available (`SHIPLIGHT_API_TOKEN` is set), use the `/cloud` skill to fetch environments and test accounts — this can pre-fill the target URL and credentials.

2. **Silent scan** — before asking questions, gather context from what's available:
   - Existing `test-context.md` (or old `test-strategy.md`) — use it to avoid asking questions already answered
   - Codebase: routes, components, `package.json`, framework
   - Git branch diff (what changed recently)
   - Existing tests (what's already covered)
   - PRDs, docs, README files
   - Cloud environments (if cloud MCP tools available)

3. **Understand what to test** — ask the user what they'd like to test, then ask targeted follow-up questions (one at a time, with recommendations based on your scan) to fill gaps: risk areas, user roles, authentication, data strategy, critical journeys. Skip questions already answered in existing context unless current evidence conflicts with them.

4. **Write `test-context.md`** containing:
   - **App profile**: name, URL, framework, key pages/features
   - **Risk profile**: what matters most, what's fragile
   - **Testing scope**: what's in/out, user roles to cover
   - **Data strategy**: how test data will be created and cleaned up
   - **Environment**: target URL, auth method, any special setup
   - **Known facts and decisions**: user-stated testing preferences, constraints, and decisions that future agents should not re-derive and that are not already represented in repository artifacts, specs, or existing tests
   - **Open questions**: unresolved or stale user questions that future agents should not repeatedly rediscover

5. **Keep context current** — during all later phases, keep `test-context.md` aligned with durable project context learned from the user, repository, implementation, and verification. Update the relevant `test-context.md` section from step 4 before ending the session.

---

## Phase 2: Specify

**Goal:** Define the outcomes this test project should give confidence in, then capture the detailed scenarios agents need to implement them. The spec should be reviewable by product owners at the top, and actionable for coding agents in the detail sections.

**Input:** reads `test-specs/test-context.md`

**Output:** `<project>/test-specs/test-spec.md`

### Steps

1. **Read** `test-context.md` to understand scope and priorities.

2. **Define outcome summary** — start `test-spec.md` with a business-readable table. Focus on product confidence, not implementation mechanics:

   | Outcome | Priority | Confidence Gained | Coverage | Gaps / Decisions |
   |---------|----------|-------------------|----------|------------------|
   | Existing users can sign in and access their workspace | P0 | Core account access works | Happy path, invalid password | MFA recovery out of scope |

3. **Add review decisions only when needed** — if there are unresolved product, scope, or risk decisions a product owner can answer, add a short **Review Decisions** table near the top. Omit this section when there are no open decisions.

   | Decision | Impact | Recommendation |
   |----------|--------|----------------|
   | Cover locked-account login? | Adds support-risk coverage | Defer unless lockout is launch-critical |

4. **Generate scenario details** — below the summary, write detailed sections for each outcome. These are for implementation and maintenance:
   - **Title**: descriptive name tied to the outcome
   - **Priority**: P0 (must-have), P1 (should-have), P2 (nice-to-have)
   - **Preconditions**: what must be true before the test starts (Given)
   - **Acceptance scenarios**: happy path and key variants in Given/When/Then form
   - **Edge cases**: at least 2 per critical outcome where meaningful (e.g., invalid input, timeout, empty state)
   - **Data requirements**: what test data is needed

5. **Review for testing risks** — scan each scenario for issues that would cause flaky or incomplete tests: data dependencies, timing/async behavior, dynamic content, auth boundaries, third-party services, state isolation, environment differences. Add a **Testing Notes** section to each detailed scenario with identified risks and mitigations. If anything is ambiguous, ask the user (one at a time, with a recommended answer and impact statement).

6. **Write `test-spec.md`** with the outcome summary first, optional review decisions second, and detailed scenario sections after that.

7. **Checkpoint** — present the outcome summary for user review:

   Ask: "Do these outcomes match the confidence you need from this test project? Any business-critical outcome missing or incorrectly out of scope?"

   **Wait for user confirmation before proceeding.**

---

## Phase 3: Plan

**Goal:** Create an actionable implementation plan with per-test guidance.

**Input:** reads `test-specs/test-spec.md`

**Output:** `<project>/test-specs/test-plan.md`

### Steps

1. **Read** `test-spec.md`.

2. **Define test file structure** — map outcomes and scenarios to test files:
   ```
   tests/
   ├── auth.setup.ts          (if auth needed)
   ├── signup.test.yaml        (Outcome 1 / scenario group)
   ├── checkout.test.yaml      (Outcome 2 / scenario group)
   └── ...
   ```

3. **Set implementation order** — ordered by:
   - Dependencies first (auth setup before authenticated tests)
   - Then by priority (P0 before P1)
   - Then by risk (highest risk first)

4. **Per-test guidance** — for each test file, specify:
   - **Data strategy**: what data to create/use, cleanup approach
   - **Flakiness risks**: specific things to watch for in this test, including any known long-running asynchronous behavior

5. **Write `test-plan.md`**.

6. **Checkpoint** — present summary:
   > Ready to implement **N** test files. Shall I proceed?

---

## Phase 4: Implement

**Goal:** Set up the project and write all YAML tests guided by the plan.

**Input:** reads `test-specs/test-plan.md`

### Setup

Skip any steps already done (project exists, deps installed, auth configured).

1. **Scaffold the project** — call `scaffold_project` with the absolute project path. This creates `package.json`, `playwright.config.ts`, `.env.example`, `.gitignore`, and `tests/`.

2. **Configure AI provider if needed** — AI providers are optional when the project already has a valid `SHIPLIGHT_API_TOKEN`; Shiplight acts as the LLM proxy and no separate model API key is required. After scaffolding, check the test project's `.env` and the current environment:

   - If `SHIPLIGHT_API_TOKEN` is present, use it and do not ask for another provider.
   - If any supported provider credentials are already configured, use them.
   - If neither is configured, ask the user to choose the lowest-friction option:

   > To run YAML tests, Shiplight needs an LLM for resolving AI-backed steps. Which setup would you like to use?
   >
   > A) **Shiplight proxy** — `SHIPLIGHT_API_TOKEN` ([Get token](https://app.shiplight.ai/settings/api-tokens)); no separate model key required
   > B) **Google AI** — `GOOGLE_API_KEY` ([Get key](https://aistudio.google.com/app/apikey))
   > C) **Anthropic** — `ANTHROPIC_API_KEY` ([Get key](https://console.anthropic.com/settings/keys))
   > D) **OpenAI** — `OPENAI_API_KEY` ([Get key](https://platform.openai.com/api-keys))
   > E) **Azure OpenAI** — requires `AZURE_OPENAI_API_KEY` + `AZURE_OPENAI_ENDPOINT`; set `WEB_AGENT_MODEL=azure:<deployment>`
   > F) **AWS Bedrock** — uses AWS credential chain; set `WEB_AGENT_MODEL=bedrock:<model_id>`
   > G) **Google Vertex AI** — uses GCP Application Default Credentials; set `WEB_AGENT_MODEL=vertex:<model>`
   > H) **I already have it configured**

   Save any provided token or key to the test project's `.env` after confirming `.env` is gitignored. For Azure, Bedrock, and Vertex, also save `WEB_AGENT_MODEL` with the appropriate `provider:model` prefix when required.

3. **Read the live schemas** — before writing any YAML, read `shiplight://yaml-test-spec` and `shiplight://schemas/action-entity`. These resources are the source of truth for top-level keys, statement syntax, action names, and action parameters.

4. **Install dependencies**:
   ```bash
   npm install
   npx playwright install chromium
   ```

5. **Set up authentication (if needed)** — follow the standard [Playwright authentication pattern](https://playwright.dev/docs/auth).

   Add credentials as variables in `playwright.config.ts`:

   ```ts
   {
     name: 'my-app',
     testDir: './tests/my-app',
     dependencies: ['my-app-setup'],
     use: {
       baseURL: 'https://app.example.com',
       storageState: 'tests/my-app/.auth/storage-state.json',
       variables: {
         username: process.env.MY_APP_EMAIL,
         password: { value: process.env.MY_APP_PASSWORD, sensitive: true },
         // otp_secret_key: { value: process.env.MY_APP_TOTP_SECRET, sensitive: true },
       },
     },
   },
   ```

   Standard variable names: `username`, `password`, `otp_secret_key`. Use `{ value, sensitive: true }` for secrets. Add values to `.env`.

   Write `auth.setup.ts` with standard Playwright login code. For TOTP, implement RFC 6238 using `node:crypto` (HMAC-SHA1 + base32 decode) — no third-party dependency needed.

   **Verify auth before proceeding.** Run the narrowest possible auth/setup target, then confirm it saves `storage-state.json`. Avoid running all tests in the project just to verify auth, because unrelated test failures can block setup. If auth fails, escalate to the user — auth is a prerequisite for everything else.

   If the test plan involves special auth requirements (e.g., one account per test, multiple roles), confirm the auth strategy with the user before proceeding.

### Write tests

For each test in the plan (or each test the user wants):

1. **Open a browser session** — call `new_session` with the app's `starting_url`.
2. **Walk through the flow** — use `inspect_page` to see the page, then `act` to perform each action. This captures locators from the response.
3. **Capture locators** — use `get_locators` for additional element info when needed.
4. **Build the YAML** — construct the `.test.yaml` content following the best practices below.
5. **Save and validate** — write the `.test.yaml` file, then call `validate_yaml_test` with the file path to check locator coverage (minimum 50% required).
6. **Close the session** — call `close_session` when done.

**Important:** Do NOT write YAML tests from imagination. Always walk through the app in a browser session first to capture real locators. Tests without locators are rejected by `validate_yaml_test`.

When guided by `test-plan.md`:
- Follow the data strategy and flakiness notes from the plan
- Cover the edge cases and assertions defined in the spec

### Run tests

After writing all tests, run them:

```bash
npx shiplight test --headed
```

**When a test fails:**

1. **Report** — tell the user which test failed and why (one sentence).
2. **Classify** the failure:
   - **Implementation fix** (wrong locator, missing assertion, timing) → fix and retry.
   - **Spec mismatch** (app behavior differs from spec) → ask the user whether to update the spec or skip the scenario.
3. **Escalate** if a fix doesn't work — don't keep retrying the same approach.

---

## Phase 5: Verify

**Goal:** Validate test coverage against the spec and reconcile any drift.

**Input:** reads `test-specs/test-context.md`, `test-specs/test-spec.md`, `test-specs/test-plan.md`, and all `.test.yaml` files

This phase only runs when spec artifacts exist.

### Coverage check

For each spec outcome, confirm the tests cover the promised scenarios and edge cases.

Present a coverage summary:

| Spec Outcome | Priority | Scenarios Specified | Tests Written | Coverage |
|--------------|----------|--------------------:|-------------:|----------|
| Existing users can sign in | P0 | 4 | 4 | ✓ |
| Buyers can complete checkout | P0 | 3 | 2 | ✗ — edge case "empty cart" not covered |

Flag gaps and extras (test steps not in the spec).

### Reconcile

Update spec artifacts to match what was actually implemented and learned:

1. **Update `test-context.md`** — keep all context sections aligned with durable project context learned during implementation and verification. Follow the section meanings from Phase 1; summarize durable context, do not paste chat logs, duplicate low-level facts already available in code/specs/tests, or store secrets. If new guidance conflicts with existing context, mark the conflict or ask before overwriting.
2. **Update `test-spec.md`** — keep the outcome summary, optional review decisions, detailed scenarios, skipped scenarios, and edge cases aligned with what was tested
3. **Update `test-plan.md`** — correct file structure, note deviations from the original plan
4. **Show diff summary** — tell the user what changed and why

This keeps artifacts accurate for future test maintenance and expansion.

---

## Additional resources

- For YAML format reference and authoring best practices (statement types, `intent` field, `js:` rules, VERIFY, waits, general conventions), see [yaml-authoring.md](yaml-authoring.md) — read this before writing any YAML tests.
- For E2E test design principles (isolation, journey scope, assertions, data strategy, parallel execution, flaky test policy), see [test-design.md](test-design.md) — apply during Phase 2 (Specify) and Phase 4 (Implement).

## Project Structure

```
my-tests/
├── test-specs/                   # Spec artifacts (version-controlled)
│   ├── test-context.md           # Phase 1: app, risk, and testing context
│   ├── test-spec.md              # Phase 2: outcome summary + detailed scenarios
│   └── test-plan.md              # Phase 3: implementation plan
│
├── playwright.config.ts
├── package.json
├── .env                          # API keys + credentials (gitignored)
├── .gitignore
│
├── tests/
│   ├── public-app/               # No login needed
│   │   ├── search.test.yaml
│   │   └── filter.test.yaml
│   │
│   └── my-saas-app/              # Requires login
│       ├── auth.setup.ts         # Playwright login setup — you write this
│       ├── dashboard.test.yaml
│       └── settings.test.yaml
```

The `test-specs/` directory contains human-readable markdown artifacts that are version-controllable. Do NOT add `test-specs/` to `.gitignore`.

## Tips

- ACTION statements with locators replay ~10x faster than DRAFTs. Always prefer ACTIONs.
- Use `inspect_page` to understand page state. **Always read the DOM file first** — it provides element indices needed for `act` and consumes far fewer tokens. Only view the screenshot when you specifically need visual information (layout, colors, images), as screenshots consume significantly more tokens than DOM.
- Run a specific project's tests with: `npx shiplight test --headed my-saas-app/`
- The `.env` file is auto-discovered by `shiplightConfig()` — no manual dotenv setup needed.
