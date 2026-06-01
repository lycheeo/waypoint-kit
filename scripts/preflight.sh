#!/usr/bin/env bash
set -euo pipefail

swift build
swift run WaypointKitValidation

rg -n \
  "sk-|OPENAI_API_KEY\\s*=\\S+|POI_PROVIDER_API_KEY\\s*=\\S+|api[_-]?key\\s*=\\s*\\\"[^\\\"]+\\\"|Bearer [A-Za-z0-9_\\-]+|VDY82RL653|BA04AF30|com\\.marinliu\\.RoadTripPlanner|f2030c7|sk-proj" \
  . \
  -g '!/.build/**' \
  -g '!/.git/**' \
  -g '!/scripts/preflight.sh' && {
    echo "Potential secret found."
    exit 1
  }

echo "Preflight passed."
