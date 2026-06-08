# Knowledge Management

Knowledge is mutable project memory for Shiplight test agents.

As you work, write down durable facts that future agents need and cannot easily derive from code, specs, or guides. This includes facts learned through interaction with the user.

Examples:

- App quirks
- Reliable setup or cleanup patterns
- Known failure modes
- Tooling gotchas
- Stable account roles or data constraints, without secrets
- Corrections to older assumptions

## Where To Write

Use `knowledge/` for operational notes discovered while working.

Use `specs/context.md` for project-wide testing context such as app profile, risk profile, target URLs or deployments, durable data strategy, and broad scope decisions.

Use `specs/tests/*.md` for feature intent, expected behavior, journeys, assertions, and coverage decisions.

## How To Write

Each note must stand alone. A future agent reading it has no memory of the chat.

- State the fact or pattern directly.
- Include enough context to make it actionable.
- Do not refer to "this task" or "what we just did".
- Do not duplicate facts already documented in specs, tests, code, or guides.
- Do not store raw secrets.

## How To Update

Knowledge is not append-only. If new user input, app behavior, or test work proves an existing note stale or incomplete:

- Update the existing note when the topic is the same.
- Merge duplicate notes when they describe the same behavior.
- Remove obsolete guidance when it would mislead future agents.
- Preserve useful historical context only when it explains why the current rule exists.
- Prefer one clear current fact over contradictory notes.

## When To Read

Before starting a task, check `knowledge/` for files relevant to the app area, target URL or deployment, auth, data, or tooling you are about to touch.

## Session-Close Reflection

Before ending an interactive testing session, ask:

- What did the user teach me that future agents should not need to ask again?
- What product behavior, app quirk, auth/data pattern, or testing preference was clarified?
- Did any existing knowledge prove stale, incomplete, or wrong?
- Does the learning belong in `knowledge/`, `specs/context.md`, or a specific `specs/tests/*.md`?

Then update the right file before the final report.
