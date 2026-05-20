# E2E Test Design Guide

These principles govern *what* to test and *how to structure* tests.

## Test isolation

Each test must run independently — never depend on another test's side effects, execution order, or leftover state. If a test needs data, it creates that data itself.

## One journey per test

Each test should verify one logical user journey. If step 3 of 8 fails, steps 4-8 give you zero information. Split long flows into focused tests.

**Exception:** Suites allow sequential dependencies between tests (e.g., test A uploads a file, test B downloads it). Each test in a suite still covers one journey — the suite just guarantees order and shares browser state.

## Assert what users see, not implementation details

Test visible outcomes — text, navigation, enabled/disabled states. Never assert CSS classes, data attributes, internal state, or DOM structure.

## Focused assertions

Verify the *one thing* that proves the feature works. Over-asserting makes tests brittle — they break on cosmetic changes unrelated to the behavior under test.

## Never test third-party services

Don't assert that Stripe's checkout, Google OAuth's consent screen, or Twilio's SMS delivery works. Mock external services at the network boundary. Test *your* integration, not their UI.

## Deterministic test data

Use unique identifiers per test run to avoid collisions. Never rely on hardcoded data that other tests or users might modify.

## Prefer API seeding over UI setup

When a test needs preconditions (a user exists, a project is created), set them up via API calls — not by clicking through the UI. UI setup is slow, flaky, and not what you're testing.

## Explicit wait policy

Minimize explicit waits. Browser actions, navigation, and assertions already include waiting behavior. Do not add a wait after ordinary page loads, clicks, form submits, or data refreshes just because the UI might change. Let the next ACTION or VERIFY prove the expected state.

## Test error states, not just happy paths

Real users hit errors. A test project that only covers happy paths gives false confidence. For every critical journey, include at least one error/edge case test.

## Design for parallel execution

Tests that modify shared global state (e.g., site-wide settings, the only admin account) can't safely run in parallel. Design around this:

- Use unique, per-test data instead of shared fixtures
- Avoid tests that change global configuration
- If a test *must* modify shared state, document it and mark it for serial execution

## Flaky test policy

A test that passes on retry is still broken. Never add retries to mask flakiness — find and fix the root cause:

- **Timing flake?** → First rely on the next action/assertion or add a targeted assertion. Only add an explicit wait when necessary.
- **Data flake?** → Use unique test data, add proper cleanup
- **Order flake?** → The test has a hidden dependency on another test — make it self-contained
- **Environment flake?** → Mock the unstable external service
