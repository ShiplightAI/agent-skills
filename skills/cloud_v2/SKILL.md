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
| 400 Bad Request | Fix the request body, IDs, or query parameters |
| 401 Unauthorized | Token is missing, invalid, expired, or for the wrong Nova environment |
| 403 Forbidden | Token lacks the required permission |
| 404 Not Found | Run, result, or artifact was not found for this organization |
| 422 Validation | Show the validation message and correct the payload |
| 500 Server Error | Retry only if the operation is idempotent; otherwise report the failure |

## REST API

Base URL: `$SHIPLIGHT_API_URL`

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
