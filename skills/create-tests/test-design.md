# E2E Test Design Best Practices

These principles govern *what* to test and *how to structure* tests — independent of the YAML format. Apply them during Phase 2 (Specify) and Phase 4 (Implement).

## Test isolation

Each test must run independently — never depend on another test's side effects, execution order, or leftover state. If a test needs data, it creates that data itself.

```yaml
# BAD: depends on a previous test having created "My Project"
goal: Delete a project
statements:
  - URL: /projects
  - intent: Click on "My Project"
    action: click
    locator: "getByText('My Project')"
  - intent: Click the Delete button
    action: click
    locator: "getByRole('button', { name: 'Delete' })"

# GOOD: creates its own data, then tests the behavior
goal: Delete a project
statements:
  - CODE: |
      const res = await page.request.post('/api/projects', {
        data: { name: 'Delete-Test-' + Date.now() }
      });
      const project = await res.json();
      save_variable('projectName', project.name);
  - URL: /projects
  - VERIFY: The project list shows the project we just created
  - intent: Click on the project we just created
    action: click
    locator: "getByText('{{projectName}}')"
  - intent: Click the Delete button
    action: click
    locator: "getByRole('button', { name: 'Delete' })"
  - VERIFY: The project is no longer visible in the list
```

## One journey per test

Each test should verify one logical user journey. If step 3 of 8 fails, steps 4-8 give you zero information. Split long flows into focused tests.

**Exception:** Suites allow sequential dependencies between tests (e.g., test A uploads a file, test B downloads it). Each test in a suite still covers one journey — the suite just guarantees order and shares browser state.

```yaml
# BAD: tests login, settings change, AND deletion in one test
goal: Full user lifecycle
statements:
  - intent: Log in
  - intent: Navigate to settings
  - intent: Change display name
  - VERIFY: Name updated
  - intent: Navigate to account
  - intent: Delete account
  - VERIFY: Account deleted

# GOOD: separate tests, each verifiable in isolation
# File: update-display-name.test.yaml
goal: Update display name from settings
statements:
  - URL: /settings
  - intent: Clear the display name field and type "New Name"
    action: input_text
    locator: "getByLabel('Display name')"
    text: "New Name"
  - intent: Click Save
    action: click
    locator: "getByRole('button', { name: 'Save' })"
  - VERIFY: Success message "Settings saved" is visible

# File: delete-account.test.yaml (separate test)
goal: Delete account from account page
statements:
  - URL: /account
  # ... focused on deletion only
```

## Assert what users see, not implementation details

Test visible outcomes — text, navigation, enabled/disabled states. Never assert CSS classes, data attributes, internal state, or DOM structure.

```yaml
# BAD: asserts implementation details
- VERIFY: The submit button uses disabled implementation markers
  js: |
    const el = await page.locator('.btn-primary');
    await expect(el).toHaveClass(/disabled/);
    await expect(el).toHaveAttribute('data-state', 'submitted');

# GOOD: asserts what a user would observe
- VERIFY: The Submit button is disabled
  js: |
    await expect(page.getByRole('button', { name: 'Submit' }))
      .toBeDisabled({ timeout: 2000 });
```

## Focused assertions

Verify the *one thing* that proves the feature works. Over-asserting makes tests brittle — they break on cosmetic changes unrelated to the behavior under test.

```yaml
# BAD: asserts every field on the page — breaks when any label changes
- VERIFY: Page title is "Dashboard"
- VERIFY: Welcome message shows username
- VERIFY: Sidebar has 5 menu items
- VERIFY: Footer shows current year
- VERIFY: Avatar image is loaded
- VERIFY: Notification bell is visible

# GOOD: asserts the one thing that proves the user landed on the dashboard
- VERIFY: Dashboard page shows the welcome message with the user's name
```

## Never test third-party services

Don't assert that Stripe's checkout, Google OAuth's consent screen, or Twilio's SMS delivery works. Mock external services at the network boundary. Test *your* integration, not their UI.

```yaml
# BAD: tests Stripe's UI (will break when Stripe updates their page)
- intent: Enter card number in Stripe iframe
- intent: Click Stripe's pay button
- VERIFY: Stripe shows success checkmark

# GOOD: mock the payment API, test your success handling
- CODE: |
    await page.route('**/api/payments', route =>
      route.fulfill({ status: 200, json: { status: 'succeeded', id: 'pi_mock' } })
    );
- intent: Click the Pay button
  action: click
  locator: "getByRole('button', { name: 'Pay' })"
- VERIFY: Order confirmation page shows "Payment successful"
```

## Deterministic test data

Use unique identifiers per test run to avoid collisions. Never rely on hardcoded data that other tests or users might modify.

```yaml
# BAD: hardcoded name — collides if tests run in parallel or data persists
- intent: Type "Test User" into the name field
  action: input_text
  locator: "getByLabel('Name')"
  text: "Test User"

# GOOD: unique per run — no collisions
- CODE: "save_variable('testName', 'Test-User-' + Date.now());"
- intent: Type the generated name into the name field
  action: input_text
  locator: "getByLabel('Name')"
  text: "{{testName}}"
```

## Prefer API seeding over UI setup

When a test needs preconditions (a user exists, a project is created), set them up via API calls — not by clicking through the UI. UI setup is slow, flaky, and not what you're testing.

```yaml
# BAD: 10 UI steps just to set up data before the real test
- URL: /projects/new
- intent: Type project name
- intent: Select team
- intent: Click Create
- VERIFY: Project page shows the newly created project
# ... now the actual test starts

# GOOD: API seed in one step, then test the real behavior
- CODE: |
    const res = await page.request.post('/api/projects', {
      data: { name: 'Seed-' + Date.now(), team: 'engineering' }
    });
    const { slug } = await res.json();
    save_variable('projectSlug', slug);
- URL: /projects/{{projectSlug}}/settings
- VERIFY: Settings page is visible
# ... test starts immediately at the point that matters
```

## Explicit wait policy

Minimize explicit waits. Browser actions, navigation, and assertions already include waiting behavior. Do not add a wait after ordinary page loads, clicks, form submits, or data refreshes just because the UI might change. Let the next ACTION or VERIFY prove the expected state.

## Test error states, not just happy paths

Real users hit errors. A test project that only covers happy paths gives false confidence. For every critical journey, include at least one error/edge case test.

```yaml
# Covers: empty state, invalid input, network failure
goal: Search handles no results gracefully
statements:
  - URL: /search
  - intent: Type a query that returns no results
    action: input_text
    locator: "getByRole('searchbox')"
    text: "zzz_no_match_zzz"
  - intent: Submit the search
    action: click
    locator: "getByRole('button', { name: 'Search' })"
  - VERIFY: Empty state message "No results found" is displayed
  - VERIFY: The search box still contains the query (user can refine)
```

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
