---
name: cloud_v2
description: "Read Shiplight Cloud v2/Nova test results: list runs, fetch run details, and stream artifact files."
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
| `trigger` | string | Exact match on trigger (`local_cli`, `gha_runner`, …) |
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
