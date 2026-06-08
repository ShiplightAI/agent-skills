#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

skill_files=(
  "skills/create-tests/SKILL.md"
  "skills/verify/SKILL.md"
)

first_run_line="2. If the timestamp file is missing, create it with the current timestamp and continue without running \`npx -y skills@latest update -y\`. Treat \`.shiplight-agent-skills-last-update\` as local cache and do not commit it."
stale_file_line="3. If the timestamp file exists and is older than 24 hours, run \`npx -y skills@latest update -y\`, then create/update the timestamp file even if the command fails."
old_line="2. If the timestamp file is missing or older than 24 hours, run \`npx -y skills@latest update -y\`, then create/update the timestamp file even if the command fails. Treat \`.shiplight-agent-skills-last-update\` as local cache and do not commit it."

for file in "${skill_files[@]}"; do
  grep -Fqx "$first_run_line" "$file"
  grep -Fqx "$stale_file_line" "$file"
  if grep -Fq "$old_line" "$file"; then
    echo "Found outdated first-run update rule in $file" >&2
    exit 1
  fi
done

for file in \
  "skills/triage/SKILL.md" \
  "skills/cloud/SKILL.md" \
  "skills/cloud_v2/SKILL.md"; do
  if grep -Fq '## Daily Skill Update Check' "$file"; then
    echo "Found unexpected daily update section in $file" >&2
    exit 1
  fi
  if grep -Fq '.shiplight-agent-skills-last-update' "$file"; then
    echo "Found unexpected timestamp reference in $file" >&2
    exit 1
  fi
done

grep -Fq '.shiplight-agent-skills-last-update' README.md
if grep -Fq '.shiplight/agent-skills-last-update' README.md; then
  echo "README.md still documents the wrong timestamp path" >&2
  exit 1
fi
grep -Fq 'On first use, if the file does not exist yet, the agent should create it and skip the update so a newly installed project does not pay for a second install.' README.md
