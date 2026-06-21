# E2E Test Design Guide

These principles govern what to test and how to structure tests.

## Test Isolation

Each test must run independently. Never depend on another test's side effects, execution order, or leftover state. If a test needs data, it creates that data itself.

## One Journey Per YAML Test

Each YAML test should verify one logical user journey or variant. If step 3 of 8 fails, steps 4-8 give you no useful information. Split long flows into focused tests.

Suites may express sequential dependencies when necessary, such as upload then download. Each test in the suite should still cover one journey.

## Specs Can Be Broader Than YAML Tests

A spec under `specs/tests/` can cover a feature or journey group. It may map to multiple smaller YAML tests.

Use specs for product confidence and YAML files for executable coverage.

## Assert What Users See

Test visible outcomes: text, navigation, enabled or disabled states, and user-observable data.

Do not assert CSS classes, data attributes, internal state, or DOM structure unless there is no user-visible alternative.

## Focused Assertions

Verify the one thing that proves the behavior works. Over-asserting makes tests brittle and causes failures on cosmetic changes.

## Never Test Third-Party Services

Do not assert that Stripe checkout, Google OAuth consent, or Twilio delivery works. Mock external services at the boundary where possible. Test your integration, not their UI.

## Deterministic Test Data

Use unique identifiers per test run to avoid collisions. Never rely on hardcoded data that other tests or users might modify.

## Prefer API Seeding Over UI Setup

When a test needs preconditions, set them up by API or helper function when possible. UI setup is slow and often tests the wrong thing.

## Explicit Wait Policy

Minimize explicit waits. Browser actions, navigation, and assertions already include waiting behavior.

Do not add waits after ordinary page loads, clicks, form submits, or data refreshes just because the UI might change. Let the next action or assertion prove expected state.

## Test Error States

Critical journeys should include at least one meaningful error or edge case. Happy-path-only coverage gives false confidence.

## Design For Parallel Execution

Tests that modify shared global state cannot safely run in parallel.

Prefer:

- Unique per-test data
- No global configuration changes
- Clear documentation for tests that must run serially

## Flaky Test Policy

A test that passes on retry is still broken. Do not add retries to mask flakiness.

- Timing flake: rely on the next action/assertion first; add targeted waits only when necessary.
- Data flake: use unique data and cleanup.
- Order flake: remove hidden dependency on another test.
- Environment flake: mock unstable external services where possible.
