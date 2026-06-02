---
name: cloud_v2
description: "Work with Shiplight Cloud v2/Nova test results APIs: create local or CI test runs, upload result artifacts, complete runs, and retrieve signed artifact URLs."
---

# Shiplight Cloud v2

## Daily Skill Update Check

Before starting this skill's work, opportunistically refresh Shiplight skills at most once per day:

1. Check the timestamp file at `.shiplight-agent-skills-last-update` in the current project.
2. If the timestamp file is missing or older than 24 hours, run `npx -y skills@latest update -y`, then create/update the timestamp file even if the command fails. Treat `.shiplight-agent-skills-last-update` as local cache and do not commit it.
3. If the update command fails, continue with the currently installed skill and mention the failure briefly.

Use the Nova results API to publish and inspect Shiplight test results from local runs, CI runs, and hosted execution. The `/v1` path segment is the API contract version.

## Setup

Use a Nova API token in `SHIPLIGHT_API_TOKEN` and the Nova API base URL in `SHIPLIGHT_API_URL`.

```bash
export SHIPLIGHT_API_URL=https://nova-api.shiplight.ai
```

All API calls require:

```text
Authorization: Bearer $SHIPLIGHT_API_TOKEN
```

If the user provides a token, append it to the project's `.env` file as `SHIPLIGHT_API_TOKEN=<token>` and tell them to keep `.env` out of git.

## Error Handling

| Error | Action |
|-------|--------|
| 400 Bad Request | Fix the request body, IDs, or query parameters. All validation errors come back as 400 — there is no separate 422. |
| 401 Unauthorized | Token is missing, invalid, expired, or for the wrong Nova environment |
| 403 Forbidden | Token lacks the required permission, the S3 URI points at a bucket other than the test-results bucket, or the URI key's first segment is not your organization ID |
| 404 Not Found | Run, result, or artifact was not found for this organization |
| 500 Server Error | Retry only if the operation is idempotent; otherwise report the failure |

## REST API

Base URL: `$SHIPLIGHT_API_URL`

### List Test Runs

Returns recent runs for the authenticated organization as a bare array (matches the v1 shape), ordered by record creation time, newest first. Note: read endpoints (list, detail) live under `/v1/test-runs`; the write endpoints (create / complete / artifact uploads) below stay under `/v1/local-runs` for compatibility with existing SDK/CLI clients.

```bash
curl -H "Authorization: Bearer $SHIPLIGHT_API_TOKEN" \
  "$SHIPLIGHT_API_URL/v1/test-runs?limit=10"
```

**Query parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `trigger` | string | Filter by trigger (e.g. `local_cli`, `gha_runner`) |
| `result` | string | Filter by overall run result. Lowercase values only: `passed`, `failed`, or `pending` (in-flight). |
| `repo` | string | Filter by repository (`org/repo`) |
| `branch` | string | Filter by branch |
| `from` | string | ISO timestamp lower bound (inclusive) on `createdAt` |
| `to` | string | ISO timestamp upper bound (inclusive) on `createdAt` |
| `page` | number | Page number (default `1`) |
| `pageSize` | number | Page size (default `20`) |
| `limit` | number | Alias for `pageSize`. If both are sent, `pageSize` wins. |

**Response:** array of run rows — `{ id, status, result, trigger, branch, commitSha, repo, target, startTime, endTime, totalTestCount, passedCount, flakyCount, failedCount, skippedCount, metadata, ... }`.

### Get Test Run

Returns the run together with its per-result rows in a single response. Equivalent to v1's `/run-results/:id`.

```bash
curl -H "Authorization: Bearer $SHIPLIGHT_API_TOKEN" \
  "$SHIPLIGHT_API_URL/v1/test-runs/42"
```

**Response:**

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

`400` if `:id` is not a numeric run ID; `404` if the run does not exist for this organization.

All `testCaseResults` for the run are returned in a single response — there is no result-level pagination. Runs with hundreds of test cases produce correspondingly large payloads.

### Create Test Run

Create a test run and result slots. The response includes presigned upload URLs for per-result video and trace artifacts.

```bash
curl -X POST "$SHIPLIGHT_API_URL/v1/local-runs" \
  -H "Authorization: Bearer $SHIPLIGHT_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d @run.json
```

Request:

```json
{
  "trigger": "local_cli",
  "startTime": "2026-05-27T10:00:00.000Z",
  "metadata": {
    "gitBranch": "main",
    "gitCommit": "abc1234",
    "gitRepo": "org/repo",
    "authorEmail": "dev@example.com",
    "ciProvider": "github_actions",
    "ciBuildId": "12345",
    "ciBuildUrl": "https://github.com/org/repo/actions/runs/12345",
    "commitTitle": "Fix checkout flow",
    "commitUrl": "https://github.com/org/repo/commit/abc1234",
    "prNumber": 42,
    "prTitle": "Fix checkout flow",
    "prUrl": "https://example.com/pr/42",
    "hostname": "runner-1",
    "nodeVersion": "v22.0.0"
  },
  "tests": [
    {
      "testCaseName": "checkout succeeds",
      "testCaseBaseName": "checkout succeeds",
      "suiteName": "Checkout",
      "file": "tests/checkout.test.yaml",
      "tags": ["smoke"],
      "suiteTags": ["commerce"],
      "baseUrl": "https://app.example.com",
      "skip": false,
      "slow": false,
      "timeout": 30000,
      "parameterSetName": "chromium",
      "videoMd5": "base64-encoded-md5",
      "traceMd5": "base64-encoded-md5"
    }
  ]
}
```

Response:

```json
{
  "testRunId": 42,
  "testCaseResults": [
    {
      "testCaseName": "checkout succeeds",
      "testCaseResultId": 101,
      "uploadUrls": {
        "video": "https://...",
        "trace": "https://...",
        "screenshots": {}
      },
      "s3Uris": {
        "video": "s3://...",
        "trace": "s3://..."
      }
    }
  ]
}
```

Useful metadata keys include `gitBranch`, `gitCommit`, `gitRepo`, `authorEmail`, `commitTitle`, `commitUrl`, `ciProvider`, `ciBuildId`, `ciBuildUrl`, `prTitle`, `prNumber`, `prUrl`, `hostname`, and `nodeVersion`. Unknown metadata may be ignored.

### Screenshot Upload URLs

Generate presigned upload URLs for result screenshots.

```bash
curl -X POST "$SHIPLIGHT_API_URL/v1/local-runs/$TEST_RUN_ID/results/$TEST_CASE_RESULT_ID/screenshot-urls" \
  -H "Authorization: Bearer $SHIPLIGHT_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"stepIds":["step-1"],"md5s":{"step-1":"base64-encoded-md5"}}'
```

Response:

```json
{
  "screenshots": {
    "step-1": "https://..."
  },
  "screenshotS3Uris": {
    "step-1": "s3://..."
  }
}
```

### Report Upload URL

Generate a presigned upload URL for a result report.

```bash
curl -X POST "$SHIPLIGHT_API_URL/v1/local-runs/$TEST_RUN_ID/results/$TEST_CASE_RESULT_ID/report-url" \
  -H "Authorization: Bearer $SHIPLIGHT_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"md5":"base64-encoded-md5"}'
```

Response:

```json
{
  "reportUrl": "https://...",
  "reportS3Uri": "s3://..."
}
```

### Complete Test Run

Mark a test run complete and attach final per-result status, timing, artifacts, and metadata.
Common `result` values are `passed`, `failed`, `skipped`, `timedout`, and `flaky`.

```bash
curl -X PUT "$SHIPLIGHT_API_URL/v1/local-runs/$TEST_RUN_ID/complete" \
  -H "Authorization: Bearer $SHIPLIGHT_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d @complete-run.json
```

Request:

```json
{
  "status": "finished",
  "endTime": "2026-05-27T10:05:00.000Z",
  "totalDuration": 300000,
  "results": [
    {
      "testCaseResultId": 101,
      "result": "passed",
      "startTime": "2026-05-27T10:00:01.000Z",
      "endTime": "2026-05-27T10:00:10.000Z",
      "error": null,
      "reportS3Uri": "s3://...",
      "videoS3Uri": "s3://...",
      "traceS3Uri": "s3://...",
      "metadata": {}
    }
  ]
}
```

Response:

```json
{
  "reportUrl": "/run-results/42"
}
```

### Artifact Read URL

Generate a signed read URL for an uploaded artifact.

```bash
curl "$SHIPLIGHT_API_URL/v1/local-runs/$TEST_RUN_ID/results/$TEST_CASE_RESULT_ID/artifact-url?type=trace" \
  -H "Authorization: Bearer $SHIPLIGHT_API_TOKEN"
```

Supported `type` values: `report`, `video`, `trace`, `screenshot`. For screenshots, include `stepId`.

```bash
curl "$SHIPLIGHT_API_URL/v1/local-runs/$TEST_RUN_ID/results/$TEST_CASE_RESULT_ID/artifact-url?type=screenshot&stepId=step-1" \
  -H "Authorization: Bearer $SHIPLIGHT_API_TOKEN"
```

Response:

```json
{
  "url": "https://...",
  "expiresIn": 3600
}
```

### Download S3 File

Proxy download for any artifact referenced by an `s3://` URI inside a result row or a nested report (e.g. step-level `screenshot_s3_path`, `messages_s3_path`). Use this when the artifact isn't one of the four well-known types covered by `artifact-url`.

```bash
curl -H "Authorization: Bearer $SHIPLIGHT_API_TOKEN" \
  "$SHIPLIGHT_API_URL/v1/s3/file?uri=s3://shipyard-test-results/<org-id>/tests/_local/test-results/<id>/report.json"
```

**Query:** `uri` (string, required) — S3 URI taken from a result row or a parsed report. Must point at the Shiplight Cloud test-results bucket and the key's first segment must equal your organization ID. Other buckets and cross-org keys return `403`. Path traversal patterns (`..`, `//`, double-encoded segments) return `400`.

**Response:** raw file contents streamed back with `Content-Disposition: attachment` — this proxy is for API/SDK consumers, never a browser renderer, so even text artifacts won't render inline. The `Content-Type` is set from a small allow-list (`video/webm`, `application/zip`, `application/json`, `image/png`, `image/jpeg`, `text/plain` for `.txt` / `.log`); any other extension — including `.html` and `.svg` — falls back to `application/octet-stream` as defense against inline-rendering attacks on the `apps/api` origin. For binary artifacts, save with `curl -o <output_file>`.

## Workflows

### Publish a Run

1. Build the run payload with one entry per discovered test.
2. `POST /v1/local-runs` and keep `testRunId`, `testCaseResultId`, upload URLs, and S3 URIs.
3. Upload videos and traces directly to the presigned URLs returned by create-run. If an MD5 was provided when requesting a URL, upload the matching content with the required checksum header.
4. For screenshots, call `screenshot-urls`, then upload each file to its presigned URL.
5. For reports, call `report-url`, then upload the report JSON to its presigned URL.
6. `PUT /v1/local-runs/{testRunId}/complete` with each final result and uploaded artifact URI.
7. Return the API response's `reportUrl` to the user.

### Retrieve an Artifact

1. Call `artifact-url` with `type=report`, `video`, `trace`, or `screenshot`.
2. Download from the returned signed URL before it expires.
3. For binary artifacts, save with an appropriate filename extension.

### Inspect a Run's Results

1. `GET /v1/test-runs?limit=10&result=failed` (or other filters) to find recent runs.
2. `GET /v1/test-runs/{testRunId}` to load `testRun` + `testCaseResults` in one round-trip.
3. For each failed `testCaseResult`, fetch the report:
   - `GET /v1/local-runs/{testRunId}/results/{testCaseResultId}/artifact-url?type=report` and download the JSON, OR
   - `GET /v1/s3/file?uri=<reportS3Uri>` to stream it directly.
4. Parse the report JSON and pull any nested `s3://` URIs (typically reporter-defined fields like `screenshot_s3_path`, `messages_s3_path`). The report schema is owned by whichever CLI/runner uploaded the report, not by this API.
5. Stream each nested artifact via `GET /v1/s3/file?uri=…`. The proxy enforces that the URI's bucket is the Shiplight test-results bucket and the key's first path segment is your organization ID, and serves the body as a forced download (see Download S3 File above for headers and content-type behavior).
