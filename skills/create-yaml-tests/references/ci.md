# CI Integration

Run a Shiplight test project in CI and upload results to Shiplight Cloud, where they appear in the read-only [cloud_v2] skill's results API for trend tracking and flaky-test detection.

Use the Shiplight CLI, not the Cloud REST API, to publish runs:

- `shiplight test` runs the tests but does **not** upload on its own.
- `shiplight report` discovers the report in `./shiplight-report`, presigns and uploads every artifact (screenshots, videos, traces), and completes the run.

Always run `report` with `if: always()` so results upload even when tests fail — otherwise a red run produces no cloud report.

There are two ways to run E2E tests in GitHub Actions. Pick one.

## Option 1 — Default GitHub-hosted runner (easiest)

Runs on a stock `ubuntu-latest` runner. The only setup is an **org API token**: create one at <https://nova.shiplight.ai/api-tokens> and store it as a repository or organization secret named `SHIPLIGHT_API_TOKEN`. No GitHub App and no admin approval needed.

Set `SHIPLIGHT_API_TOKEN` at the job's `env` (global) scope — **every** `npx shiplight` command needs it, not just `report`. `shiplight report` additionally needs `SHIPLIGHT_REPORT_TO_CLOUD=1` to actually upload. Stock runners have no browser preinstalled, so install Chromium first.

Create `.github/workflows/e2e.yml`:

```yaml
name: E2E Tests

on:
  push:
    branches: [main]
  pull_request:

jobs:
  e2e:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    env:
      SHIPLIGHT_API_TOKEN: ${{ secrets.SHIPLIGHT_API_TOKEN }}   # needed by every `npx shiplight` command
    steps:
      - uses: actions/checkout@v5

      - name: Install dependencies
        working-directory: tests/e2e
        run: npm install

      - name: Install Playwright browser
        working-directory: tests/e2e
        run: npx playwright install --with-deps chromium

      - name: Run E2E tests
        working-directory: tests/e2e
        run: npx shiplight test

      - name: Upload results to Shiplight
        if: always()                       # upload even when tests fail
        working-directory: tests/e2e
        env:
          SHIPLIGHT_REPORT_TO_CLOUD: '1'   # required on non-Shiplight runners to enable upload
        run: npx shiplight report
```

## Option 2 — Shiplight-hosted runner

Runs on an ephemeral `shiplight-*` VM with Chromium + Playwright preinstalled and credentials provisioned per run — so **no `SHIPLIGHT_API_TOKEN`, no `SHIPLIGHT_REPORT_TO_CLOUD`, and no browser install step**. Do not run `npx playwright install`; the image already has it.

Requires one-time setup: install the Shiplight GitHub App on the repo/org (**this may need your IT/admin's approval**), then have an org owner enable runners in Org Settings (<https://nova.shiplight.ai/org?tab=settings>).

Create `.github/workflows/e2e.yml`:

```yaml
name: E2E Tests

on:
  push:
    branches: [main]
  pull_request:

jobs:
  e2e:
    runs-on: shiplight-small     # ephemeral Shiplight runner; sizes below
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v5

      - name: Install dependencies
        working-directory: tests/e2e
        run: npm install

      - name: Run E2E tests
        working-directory: tests/e2e
        run: npx shiplight test

      - name: Upload results to Shiplight
        if: always()
        working-directory: tests/e2e
        run: npx shiplight report
```

Runner sizes: `shiplight-small` (4 vCPU / 16 GB), `shiplight-medium` (8 / 32), `shiplight-large` (16 / 64), `shiplight-xlarge` (32 / 128).

## Notes

- `working-directory: tests/e2e` assumes the Shiplight project lives there. Adjust to your project root.
- For custom integrations the CLI doesn't cover (non-Shiplight test frameworks, bespoke pipelines), the raw publish REST calls live outside this skill; the [cloud_v2] skill documents only the read side.

[cloud_v2]: ../../cloud_v2/SKILL.md
