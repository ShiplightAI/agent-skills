# YAML Authoring Reference

## YAML Format Reference

Read `shiplight://yaml-test-spec` for the full YAML language spec.

Read `shiplight://schemas/action-entity` for the full list of available actions and parameters.

These resources are the source of truth for top-level keys, statement syntax, action names, and action parameters.

## Statement Type Selection

- ACTION is the default. Capture locators with browser tools, then write ACTION statements.
- DRAFT is a last resort. Use it only when the locator is genuinely unknowable at authoring time.
- VERIFY is for assertions.
- URL is for navigation. Prefer `URL: /path` over a go-to-url action.
- `description:` plus `js:` is for network mocking, localStorage manipulation, or page-level scripting. Do not use raw JS for clicks, normal assertions, or navigation.

## Intent Field

`intent` defines what the step should accomplish. `action` and `locator` are caches of how to do it.

When a cache fails, the AI agent uses `intent` to re-inspect the page and regenerate the action. Intent must be specific enough for an agent to act on without chat history.

Bad:

```yaml
- intent: Click button
- intent: Click the 3rd button in the form
- intent: Click element at index 42
```

Good:

```yaml
- intent: Click the Submit button to save the new project
  action: click
  locator: "getByRole('button', { name: 'Submit' })"
```

Describe the user goal, not DOM position or implementation detail.

## ACTION Format

Use structured ACTION format by default for supported actions. Read `shiplight://schemas/action-entity` before writing or changing actions.

## VERIFY Best Practices

`VERIFY:` has two modes:

- Natural language only: AI inspects the page and judges whether the statement is true.
- With `js:`: JavaScript runs first as a fast deterministic check. If it throws, AI fallback re-inspects the page.

```yaml
- VERIFY: The search dialog is visible.

- VERIFY: The search dialog is visible.
  js: await expect(page.getByTestId('search-dialog-container')).toBeVisible({ timeout: 2000 })
```

Use natural language when there is no reliable locator or the check is semantic.

Use `js:` when there is a stable locator and the assertion can be a simple Playwright `expect()`.

`js:` rules in VERIFY:

- Keep it to a single simple Playwright `expect()` call.
- `page`, `agent`, and `expect` are available.
- Set a short timeout, such as `{ timeout: 2000 }`.
- Resolve locators to a single element to avoid strict-mode errors.
- Remember that fallback only triggers when `js` throws.

Always use `VERIFY:` shorthand. Do not use `action: verify` directly.

## IF And WHILE Conditions

Use natural-language AI conditions for DOM-based checks. They can self-heal when the DOM changes.

Use `js:` conditions only for counter or state logic, such as:

```yaml
js: retryCount < 3
```

Do not use `js:` conditions for DOM inspection.

## Waiting

- `WAIT:` is a fixed-duration pause. Use only for known delays.
- `WAIT_UNTIL:` checks a condition repeatedly until met or timed out. It makes model calls, so use it only for long conditional waits.

Minimize explicit waits. Browser actions, navigation, and assertions already include waiting behavior.

Do not add waits after ordinary page loads, clicks, form submits, or data refreshes just because the UI might change. Let the next action or assertion prove expected state.

## File Downloads

Downloads are tracked automatically on every page, including popups and new tabs. Each downloaded file is saved into the test's output directory under `downloads/`.

Two primitives carry download support; everything else is an ordinary test step:

1. `action: wait_for_download_complete` — blocks until the tracked download finishes. It also covers downloads that have not started yet, so size `timeout_seconds` (default 10) to cover server-side file generation plus transfer time.
2. `agent.getRecentDownloadedFilePath()` — call it in a `js:` block to get the local path of the saved file. From there it is a normal file: read it, parse it, assert on its contents, or pass it to a later step.

Example shape — the trigger step and the assertions are placeholders; adapt them to what the real test must prove (file contents, row counts, re-upload, etc.):

```yaml
- intent: Click the Export CSV button
  action: click
  locator: "getByRole('button', { name: 'Export CSV' })"

- intent: Wait for the export download to complete
  action: wait_for_download_complete
  timeout_seconds: 30

- description: Verify the downloaded file is non-empty
  js: |
    const filePath = agent.getRecentDownloadedFilePath();
    expect(filePath).toContain('.csv');
    const fs = await import('node:fs');
    expect(fs.statSync(filePath).size).toBeGreaterThan(0);
```

Only the most recent download is tracked. Wait for and verify each download before triggering the next one.

## General Conventions

- Put `intent` first in ACTION statements.
- `xpath` is only needed when an ACTION has no `locator`.
- Use a single-test file for isolated tests.
- Use a suite only when tests have a real sequential dependency.
- Use parameters for the same test structure with different data inputs.
