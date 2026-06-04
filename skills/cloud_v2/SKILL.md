---
name: cloud_v2
description: "Read Shiplight Cloud v2/Nova test results: list runs, fetch run details, and download artifacts."
---

# Shiplight Cloud v2

## Daily Skill Update Check

Before starting this skill's work, opportunistically refresh Shiplight skills at most once per day:

1. Check the timestamp file at `.shiplight-agent-skills-last-update` in the current project.
2. If the timestamp file is missing or older than 24 hours, run `npx -y skills@latest update -y`, then create/update the timestamp file even if the command fails. Treat `.shiplight-agent-skills-last-update` as local cache and do not commit it.
3. If the update command fails, continue with the currently installed skill and mention the failure briefly.

Read-only access to test results uploaded by the Shiplight CLI / CI runner. The `/v1` segment is the API contract version. Do not attempt to publish runs through this skill.

## Setup

```bash
export SHIPLIGHT_API_URL=https://nova-api.shiplight.ai
```

All API calls require:

```text
Authorization: Bearer $SHIPLIGHT_API_TOKEN
```

If the user provides a token, append it to the project's `.env` file as `SHIPLIGHT_API_TOKEN=<token>` and tell them to keep `.env` out of git.

## CI Integration

In CI, use the `shiplight report` CLI instead of calling the REST API below directly — it discovers the test report in `./shiplight-report`, presigns and uploads every artifact, and completes the run for you. Reach for the raw REST calls only for custom integrations the CLI doesn't cover (non-Shiplight test frameworks, bespoke pipelines).

```yaml
- name: Run E2E tests
  working-directory: tests/e2e
  run: npx shiplight test

- name: Upload results to Shiplight
  if: always()            # upload even when tests fail
  working-directory: tests/e2e
  run: npx shiplight report
```

`shiplight test` does **not** upload on its own. `shiplight report` uploads to cloud.

Always use `if: always()` so results upload even when tests fail; otherwise a red run produces no cloud report.

### On Shiplight CI runners 

One-time setup: install the Shiplight GitHub App on the repo/org, then have an org owner enable runners in Org Settings (<https://nova.shiplight.ai/org?tab=settings>).

Change `runs-on` in the workflow to a `shiplight-*` host type:
```yaml
  runs-on: shiplight-small
```

**No env config is needed**; `npx shiplight report` works as-is. Chromium + Playwright are preinstalled, so do not run `npx playwright install`.

### On any other runner (GitHub-hosted, GitLab, local, etc.)

Get an org API token from <https://nova.shiplight.ai/api-tokens> and store it as a CI secret:

```yaml
- name: Upload results to Shiplight
  if: always()
  working-directory: tests/e2e
  env:
    SHIPLIGHT_REPORT_TO_CLOUD: '1'
    SHIPLIGHT_API_TOKEN: ${{ secrets.SHIPLIGHT_API_TOKEN }}
  run: npx shiplight report
```

## Error Handling

| Status | Action |
|--------|--------|
| 400 | Fix the request, IDs, or query parameters. All validation errors return 400. |
| 401 | Token is missing, invalid, expired, or for the wrong Nova environment. |
| 403 | Token lacks permission; or the S3 URI points at a non-test-results bucket; or the URI key's first segment is not your organization ID. |
| 404 | Run, result, or artifact not found for this organization. |
| 500 | Retry only if idempotent. |

## REST API

Base URL: `$SHIPLIGHT_API_URL`

### List Test Runs

```bash
curl -H "Authorization: Bearer $SHIPLIGHT_API_TOKEN" \
  "$SHIPLIGHT_API_URL/v1/test-runs?pageSize=10"
```

Returns a bare array ordered by `createdAt` descending.

| Param | Type | Description |
|-------|------|-------------|
| `result` | string | Exact match on overall run result. Lowercase: `passed`, `failed`, `pending` |
| `repo` | string | Exact match on `org/repo` |
| `branch` | string | Exact match on branch |
| `from` | string | ISO timestamp lower bound (inclusive) on `createdAt` |
| `to` | string | ISO timestamp upper bound (inclusive) on `createdAt` |
| `page` | number | Default `1` |
| `pageSize` | number | Default `20` |

**Response:** array of `{ id, status, result, trigger, branch, commitSha, repo, target, startTime, endTime, totalTestCount, passedCount, flakyCount, failedCount, skippedCount, metadata, ... }`.

### Get Test Run

```bash
curl -H "Authorization: Bearer $SHIPLIGHT_API_TOKEN" \
  "$SHIPLIGHT_API_URL/v1/test-runs/42"
```

Returns the run plus every `testCaseResult` row — no result-level pagination.

```json
{
  "testRun": {
    "id": 42,
    "status": "finished",
    "result": "passed",
    "trigger": "local_cli",
    "branch": "main",
    "totalTestCount": 1,
    "passedCount": 1,
    "failedCount": 0
  },
  "testCaseResults": [
    {
      "id": 101,
      "testRunId": 42,
      "result": "passed",
      "reportS3Uri": "s3://shipyard-test-results/org-1/tests/_local/test-results/101/report.json",
      "videoS3Uri": "s3://...",
      "traceS3Uri": "s3://..."
    }
  ]
}
```

`400` if `:id` is not numeric; `404` if the run does not exist.

### List Test Results by File

```bash
curl -H "Authorization: Bearer $SHIPLIGHT_API_TOKEN" \
  "$SHIPLIGHT_API_URL/v1/test-results?repo=org/repo&file=tests/checkout.spec.ts&pageSize=10"
```

Returns a bare array ordered by result `createdAt` descending. Each row carries the test result fields plus a nested `testRun` with parent context (branch, commit, repo).

| Param | Type | Description |
|-------|------|-------------|
| `repo` | string | **Required.** Exact match on `org/repo`. |
| `file` | string | **Required.** Exact match on the test file path stored on the result row. |
| `result` | string | Lowercase: `passed`, `failed`, `pending` |
| `branch` | string | Exact match on branch |
| `from` | string | ISO timestamp lower bound (inclusive) on result `createdAt` |
| `to` | string | ISO timestamp upper bound (inclusive) on result `createdAt` |
| `page` | number | Default `1` |
| `pageSize` | number | Default `20` |

```json
[
  {
    "id": 101,
    "testRunId": 42,
    "file": "tests/checkout.spec.ts",
    "testName": "checkout succeeds",
    "status": "finished",
    "result": "passed",
    "startTime": "2026-05-27T10:00:01.000Z",
    "endTime": "2026-05-27T10:00:10.000Z",
    "errorMessage": null,
    "reportS3Uri": "s3://shipyard-test-results/org-1/tests/_local/test-results/101/report.json",
    "videoS3Uri": "s3://...",
    "traceS3Uri": "s3://...",
    "createdAt": "2026-05-27T10:00:11.000Z",
    "testRun": {
      "id": 42,
      "branch": "main",
      "commitSha": "abc1234",
      "repo": "org/repo",
      "createdAt": "2026-05-27T10:00:00.000Z"
    }
  }
]
```

`400` if `repo` or `file` is missing.

### Download S3 File

```bash
curl -H "Authorization: Bearer $SHIPLIGHT_API_TOKEN" \
  "$SHIPLIGHT_API_URL/v1/s3/file?uri=s3://shipyard-test-results/<org-id>/tests/_local/test-results/<id>/report.json"
```

**Query:** `uri` (string, required). Bucket must be the Shiplight test-results bucket; the key's first segment must equal your organization ID. Other buckets and cross-org keys return `403`. `..`, `//`, and double-encoded segments return `400`.

**Response:** raw bytes with `Content-Disposition: attachment` (always a download, never inline). `Content-Type` is set from an extension allow-list (`webm`, `zip`, `json`, `txt`, `log`, `png`, `jpg`, `jpeg`); any other extension — including `.html` and `.svg` — returns `application/octet-stream`. Save binaries with `curl -o <file>`.

## Workflows

### Inspect a Run's Results

1. `GET /v1/test-runs?pageSize=10&result=failed` (or other filters) to find recent failures.
2. `GET /v1/test-runs/{testRunId}` to load `testRun` + `testCaseResults`.
3. For each failed `testCaseResult`, `GET /v1/s3/file?uri=<reportS3Uri>` to fetch the report JSON.
4. Parse the report and stream any nested `s3://` URIs via `GET /v1/s3/file?uri=…`. Report schema is reporter-defined; expect arbitrary fields containing `s3://` values.
