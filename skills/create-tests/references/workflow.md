# Workflow

Use this phased workflow for broad requests such as creating a new test project, planning coverage for a feature, or adding multiple tests.

```text
Phase 1: Discover  -> specs/context.md
Phase 2: Specify   -> specs/tests/*.md
Phase 3: Plan      -> implementation plan in the relevant spec(s)
Phase 4: Implement -> tests/*.test.yaml, environments, auth, helpers
Phase 5: Verify And Reflect -> updated specs, context, and knowledge
```

For narrow requests, such as fixing one failing test, use the relevant task guide directly.

## Phase 1: Discover

Understand the application, user goals, risks, target environment, auth needs, and data strategy.

Before asking questions, scan available context:

- Existing `specs/context.md`
- Existing specs in `specs/tests/`
- Codebase routes, components, framework, and `package.json`
- Git branch diff
- Existing tests
- README, PRDs, and docs
- Existing `knowledge/` notes

Write or update `specs/context.md` with:

- App profile: name, framework, key pages and features
- Risk profile: what matters most and what is fragile
- Testing scope: in-scope and out-of-scope areas
- User roles: roles and permission levels to cover
- Data strategy: how test data is created and cleaned up
- Environment: target deployments, auth method, special setup
- Known facts and decisions: durable preferences and constraints
- Open questions: unresolved or stale questions

Do not store raw secrets.

## Phase 2: Specify

Create or update specs under `specs/tests/`. Each spec should cover a feature, capability, or journey group. A spec may map to multiple smaller YAML tests.

Start each spec with a business-readable confidence summary, then include actionable scenario detail.

Use `references/test-spec-template.md` for new specs.

If a broad request affects many journeys, present the outcome summary and ask:

> Do these outcomes match the confidence you need from this test project? Any business-critical outcome missing or incorrectly out of scope?

Wait for user confirmation before spending substantial time walking the app and implementing YAML.

## Phase 3: Plan

Add or update the `Implementation Plan` section in the relevant spec(s):

- Test files to create or update
- Implementation order
- Environment and auth to use
- Data setup and cleanup strategy
- Flakiness risks and mitigations

Order work by dependencies first, then priority, then risk.

## Phase 4: Implement

Set up or update project files as needed:

1. Create missing project directories.
2. Create or update `environments/*.env.yaml`.
3. Create or reuse auth login modules when needed.
4. Read `shiplight://yaml-test-spec` and `shiplight://schemas/action-entity`.
5. Walk the app in a browser and capture real locators.
6. Write focused YAML tests.
7. Validate YAML with `validate_yaml_test`.
8. Run the narrowest relevant test command.

Do not write tests from memory.

## Phase 5: Verify And Reflect

Reconcile artifacts with implementation, then run the session-close reflection from `references/knowledge.md`:

- Confirm each specified journey or variant has matching YAML coverage or a documented gap.
- Update affected `specs/tests/*.md` with implemented test paths, skipped scope, and known gaps.
- Update `specs/context.md` or `knowledge/` when the session produced durable learning.
- Correct stale knowledge when new evidence supersedes it.
- Report files changed, commands run, and any unresolved mismatch.
