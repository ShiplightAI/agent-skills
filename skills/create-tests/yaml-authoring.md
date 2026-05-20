# YAML Authoring Reference

## YAML Format Reference

Read the MCP resource `shiplight://yaml-test-spec` for the full language spec (statement types, templates, variables, suites, hooks, parameterized tests).

Read the MCP resource `shiplight://schemas/action-entity` for the full list of available actions and their parameters.

## YAML Authoring Best Practices

These best practices bridge the YAML language spec and the action catalog to help you write fast, reliable tests.

### Statement type selection

- **ACTION is the default.** Capture locators via MCP tools (`act`, `get_locators`) during browser sessions, then write ACTION statements. ACTIONs replay deterministically (~1s).
- **DRAFT is a last resort.** Only use DRAFT when the locator is genuinely unknowable at authoring time. DRAFTs are slow (~5-10s each, AI resolution at runtime). Tests with too many DRAFTs are rejected by `validate_yaml_test`.
- **VERIFY for assertions.** Use `VERIFY:` for all assertions. 
- **URL for navigation.** Use `URL: /path` for navigation instead of `action: go_to_url`.
- **`js:` for scripting.** Use a `description:` + `js:` statement for network mocking, localStorage manipulation, page-level scripting. Not for clicks, assertions, or navigation.

### The `intent` field

`intent` is the **intent** of the step — it defines _what_ the step should accomplish. The `action`/`locator` fields are **caches** of _how_ to do it. When a cache fails (stale locator, changed DOM), the AI agent uses `intent` to re-inspect the page and regenerate the action from scratch. Structured actions self-heal this way; raw `js:` code runs verbatim and does not.

Because `intent` drives self-healing, it must be specific enough for an agent to act on without any other context. Describe the **user goal**, not the DOM element — avoid element indices, CSS selectors, or positional references that break when the UI changes:

```yaml
# BAD: vague, agent can't re-derive the action
- intent: Click button

# BAD: tied to DOM structure that can change
- intent: Click the 3rd button in the form
- intent: Click element at index 42

# GOOD: describes the user goal, stable across UI changes
- intent: Click the Submit button to save the new project
  action: click
  locator: "getByRole('button', { name: 'Submit' })"
```

### ACTION: structured format

**Use structured format by default** for all supported actions. Read the MCP resource `shiplight://schemas/action-entity` for the full list of available actions and their parameters.

### VERIFY best practices

`VERIFY:` has two modes:

- **Natural language only** — the AI inspects the page and judges whether the statement is true. Slower but self-healing.
- **With `js:`** — the JS runs first as a fast, deterministic check. If it throws (element not found, timeout, assertion failure), AI fallback kicks in to re-inspect the page.

```yaml
# Natural language only — AI inspects the page
- VERIFY: The search dialog is visible.

# With js: — JS runs first, AI fallback on throw
- VERIFY: The search dialog is visible.
  js: await expect(page.getByTestId('search-dialog-container')).toBeVisible({ timeout: 2000 })
```

**When to use each:**
- Use natural language only when you don't have a reliable locator, or the check is inherently semantic (e.g., "the error message describes a permission problem").
- Use `js:` when you have a stable locator and want fast, deterministic verification with AI as a fallback.

**`js:` rules:**
- **Keep it simple** — `js:` should only be a single Playwright `expect()` call (e.g., `toBeVisible`, `toHaveText`, `toHaveValue`). If the assertion requires complex logic, multi-step queries, or conditional checks, omit `js:` and let AI handle it via natural language.
- `page`, `agent`, and `expect` are available in scope
- Always set a short timeout (e.g., `{ timeout: 2000 }`) so stale locators fall back to AI quickly instead of waiting the default 5s
- Always resolve locators to a single element (e.g., `.first()`, `.nth(1)`) to avoid Playwright strict-mode errors
- **The AI fallback only triggers when `js` throws.** If `js` passes against the wrong element (stale selector matching a different element), the assertion silently succeeds — no fallback occurs. Keep `js:` assertions simple and specific to minimize this risk.

Always use `VERIFY:` shorthand — do not use `action: verify` directly.

### IF/WHILE `js:` condition best practices

- **Use natural language (AI) conditions for DOM-based checks** (element visible, text present, page state). AI conditions self-heal against DOM changes; `js:` conditions are brittle and cannot auto-heal.
- **Use `js:` conditions only for counter/state logic** — e.g., `js: counter++ < 10`, `js: retryCount < 3`. Never use `js:` for DOM inspection like `js: document.querySelector('.modal') !== null`.
- If you need a JavaScript-based DOM check, use a `description: + js:` statement to evaluate it and store the result, or use `VERIFY:` with `js:` (which at least has AI fallback on failure).

### Waiting syntax

- **`WAIT:`** — fixed-duration pause. Use only for known delays. Use `seconds:` to set duration.
- **`WAIT_UNTIL:`** — AI checks the condition repeatedly until met or timeout. It makes LLM model calls. Use it only for long conditional waits.

See the explicit wait policy in [test-design.md](test-design.md) for when to use each.

### General conventions

- Put `intent` first in ACTION statements for readability
- `xpath` is only needed when an ACTION has no `locator`.
- **Single-test vs Suite vs Parameters:**
  - **Single-test file** — one isolated test, no shared state
  - **Suite** — tests that have sequential dependencies (e.g., test A creates a file, test B consumes it). Each test in a suite still covers one journey — the suite just guarantees execution order and shares browser state. Do NOT use suites to bundle unrelated tests.
  - **Parameters** — same test structure, different data inputs
