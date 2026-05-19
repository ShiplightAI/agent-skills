# YAML Authoring Reference

## YAML Format Reference

Read the MCP resource `shiplight://yaml-test-spec-v1.3.0` for the full language spec (statement types, templates, variables, suites, hooks, parameterized tests).

Read the MCP resource `shiplight://schemas/action-entity` for the full list of available actions and their parameters.

## YAML Authoring Best Practices

These best practices bridge the YAML language spec and the action catalog to help you write fast, reliable tests.

### Statement type selection

- **ACTION is the default.** Capture locators via MCP tools (`act`, `get_locators`) during browser sessions, then write ACTION statements. ACTIONs replay deterministically (~1s).
- **DRAFT is a last resort.** Only use DRAFT when the locator is genuinely unknowable at authoring time. DRAFTs are slow (~5-10s each, AI resolution at runtime). Tests with too many DRAFTs are rejected by `validate_yaml_test`.
- **VERIFY for assertions.** Use `VERIFY:` for all assertions. Do not write assertion DRAFTs like `"Check that the button is visible"`.
- **URL for navigation.** Use `URL: /path` for navigation instead of `action: go_to_url`.
- **CODE for scripting.** Use `CODE:` for network mocking, localStorage manipulation, page-level scripting. Not for clicks, assertions, or navigation.

### The `intent` field

`intent` is the **intent** of the step — it defines _what_ the step should accomplish. The `action`/`locator` or `js` fields are **caches** of _how_ to do it. When a cache fails (stale locator, changed DOM), the AI agent uses `intent` to re-inspect the page and regenerate the action from scratch.

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

### ACTION: structured format vs `js:` shorthand

**Use structured format by default** for all supported actions. Read the MCP resource `shiplight://schemas/action-entity` for the full list of available actions and their parameters.

**Use `js:` only when the action doesn't map to a supported action** — e.g., complex multi-step interactions, custom Playwright API calls, or chained operations:

```yaml
- intent: Drag slider to 50% position
  js: "await page.getByRole('slider').first().fill('50')"
```

### `js:` coding rules

- Always resolve locators to a single element (e.g., `.first()`, `.nth(1)`) to avoid Playwright strict-mode errors
- Always include `{ timeout: 5000 }` on actions for predictable timing
- The `intent` is critical — it's the input for self-healing when `js` fails
- `page`, `agent`, and `expect` are available in scope

### VERIFY best practices

- Always set a short timeout (e.g., `{ timeout: 2000 }`) on `js:` assertions that have an AI fallback, so stale locators fall back to AI quickly instead of waiting the default 5s
- Always use `VERIFY:` shorthand — do not use `action: verify` directly
- **Be aware of false negatives with `js:` assertions.** The AI fallback only triggers when `js` **throws** (element not found, timeout). If `js` passes against the wrong element (stale selector matching a different element), the assertion silently succeeds — no fallback occurs. Keep `js:` assertions simple and specific to minimize this risk.

### IF/WHILE `js:` condition best practices

- **Use natural language (AI) conditions for DOM-based checks** (element visible, text present, page state). AI conditions self-heal against DOM changes; `js:` conditions are brittle and cannot auto-heal.
- **Use `js:` conditions only for counter/state logic** — e.g., `js: counter++ < 10`, `js: retryCount < 3`. Never use `js:` for DOM inspection like `js: document.querySelector('.modal') !== null`.
- If you need a JavaScript-based DOM check, use `CODE:` to evaluate it and store the result, or use `VERIFY:` with `js:` (which at least has AI fallback on failure).

### Waiting syntax

- **`WAIT:`** — fixed-duration pause. Use only for known delays. Use `seconds:` to set duration.
- **`WAIT_UNTIL:`** — AI checks the condition repeatedly until met or timeout. It makes LLM model calls. Use it only for long conditional waits.

See the explicit wait policy in [test-design.md](test-design.md) for when to use each.

### General conventions

- Put `intent` first in ACTION statements for readability
- `xpath` is only needed when an ACTION has neither `locator` nor `js`.
- **Single-test vs Suite vs Parameters:**
  - **Single-test file** — one isolated test, no shared state
  - **Suite** — tests that have sequential dependencies (e.g., test A creates a file, test B consumes it). Each test in a suite still covers one journey — the suite just guarantees execution order and shares browser state. Do NOT use suites to bundle unrelated tests.
  - **Parameters** — same test structure, different data inputs
