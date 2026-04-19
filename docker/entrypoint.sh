#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: opencode-entrypoint <config_selector> <prompt_ssm_parameter> [command ...]

Required environment variables:
  CONFIG_BUCKET            S3 bucket containing configuration files

Optional environment variables:
  CONFIG_PREFIX                    S3 key prefix for configuration objects (default: configs)
  CONFIG_OBJECT_SUFFIX             Configuration object suffix (default: .json)
  RUNTIME_CONFIG_PATH              Local path for resolved runtime config (default: /workspace/opencode.config.resolved.json)
  RESULT_BUCKET                    Destination S3 bucket for task results
  RESULT_PREFIX                    Destination S3 key prefix for task results (default: results)
  RESULT_LOCAL_PATH                Local output artifact to upload after run (optional)
  MAX_TASK_DURATION_SECONDS        Runtime cap in seconds (default: 3600, max expected on ECS scheduler)
USAGE
}

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

CONFIG_SELECTOR="$1"
PROMPT_PARAMETER_NAME="$2"
shift 2

if [[ ! "$CONFIG_SELECTOR" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Invalid config selector '$CONFIG_SELECTOR'. Allowed: letters, numbers, dot, underscore, dash." >&2
  exit 1
fi

: "${CONFIG_BUCKET:?CONFIG_BUCKET is required}"

CONFIG_PREFIX="${CONFIG_PREFIX:-configs}"
CONFIG_OBJECT_SUFFIX="${CONFIG_OBJECT_SUFFIX:-.json}"
RUNTIME_CONFIG_PATH="${RUNTIME_CONFIG_PATH:-/workspace/opencode.config.resolved.json}"
MAX_TASK_DURATION_SECONDS="${MAX_TASK_DURATION_SECONDS:-3600}"

S3_CONFIG_URI="s3://${CONFIG_BUCKET}/${CONFIG_PREFIX%/}/${CONFIG_SELECTOR}${CONFIG_OBJECT_SUFFIX}"

echo "Downloading config from ${S3_CONFIG_URI}"
aws s3 cp "$S3_CONFIG_URI" "$RUNTIME_CONFIG_PATH"

echo "Fetching unattended prompt from SSM parameter ${PROMPT_PARAMETER_NAME}"
PROMPT_VALUE="$(aws ssm get-parameter --name "$PROMPT_PARAMETER_NAME" --with-decryption --query 'Parameter.Value' --output text)"

python3 - "$RUNTIME_CONFIG_PATH" <<'PY'
import base64
import json
import re
import subprocess
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
content = config_path.read_text(encoding="utf-8")
pattern = re.compile(r"\{\{(PARAM|SECRET):([^}]+)\}\}")
cache = {}

def aws_cli(*args):
    return subprocess.check_output(["aws", *args], text=True).strip()

def resolve(kind, key):
    cache_key = (kind, key)
    if cache_key in cache:
        return cache[cache_key]

    if kind == "PARAM":
        value = aws_cli("ssm", "get-parameter", "--name", key, "--with-decryption", "--query", "Parameter.Value", "--output", "text")
    else:
        payload = aws_cli("secretsmanager", "get-secret-value", "--secret-id", key, "--output", "json")
        data = json.loads(payload)
        if "SecretString" in data and data["SecretString"] is not None:
            value = data["SecretString"]
        else:
            value = base64.b64decode(data.get("SecretBinary", "")).decode("utf-8")

    cache[cache_key] = value
    return value

resolved = pattern.sub(lambda m: resolve(m.group(1), m.group(2).strip()), content)
config_path.write_text(resolved, encoding="utf-8")
PY

export OPENCODE_CONFIG_FILE="$RUNTIME_CONFIG_PATH"
export OPENCODE_UNATTENDED_PROMPT="$PROMPT_VALUE"

if [[ -n "${RESULT_BUCKET:-}" ]]; then
  export OPENCODE_RESULTS_S3_URI="s3://${RESULT_BUCKET}/${RESULT_PREFIX:-results}/${CONFIG_SELECTOR}/"
fi

if [[ $# -eq 0 ]]; then
  set -- opencode
fi

echo "Executing command: $*"
set +e
timeout "$MAX_TASK_DURATION_SECONDS" "$@"
exit_code=$?
set -e

if [[ -n "${RESULT_BUCKET:-}" && -n "${RESULT_LOCAL_PATH:-}" && -f "${RESULT_LOCAL_PATH}" ]]; then
  RESULT_KEY="${RESULT_PREFIX:-results}/${CONFIG_SELECTOR}/$(date -u +%Y%m%dT%H%M%SZ)-result.json"
  echo "Uploading task result to s3://${RESULT_BUCKET}/${RESULT_KEY}"
  aws s3 cp "${RESULT_LOCAL_PATH}" "s3://${RESULT_BUCKET}/${RESULT_KEY}"
fi

exit "$exit_code"
