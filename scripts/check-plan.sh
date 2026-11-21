#!/usr/bin/env bash
# Destructive-change gate: check-plan.sh <plan.json>  (output of `terraform show -json <planfile>`)
# Fails (exit 1) if any resource is deleted or replaced, unless ALLOW_DESTROY=true.
# ALLOW_DESTROY is a deliberate override: in CI only via the workflow_dispatch input allow_destroy,
# after someone reviewed the deletes in the plan. Exit 2 = usage or unreadable plan.
set -euo pipefail

[[ $# -eq 1 ]] || { echo "usage: $0 <plan.json>" >&2; exit 2; }
plan_json=$1

# Refuse anything that is not a plan document, so a failed `terraform show` never passes the gate.
jq -e 'type == "object" and has("format_version")' "$plan_json" >/dev/null 2>&1 ||
  { echo "error: $plan_json is not a terraform plan JSON" >&2; exit 2; }

# A replace shows up as ["delete","create"] or ["create","delete"], so matching "delete" covers both.
deletes=$(jq -r '.resource_changes[]? | select(.change.actions | index("delete")) | "\(.change.actions | join(","))\t\(.address)"' "$plan_json")

if [[ -z $deletes ]]; then
  echo "check-plan: no deletes or replaces"
  exit 0
fi

echo "check-plan: plan deletes or replaces resources:"
echo "$deletes"
if [[ ${ALLOW_DESTROY:-false} == "true" ]]; then
  echo "check-plan: ALLOW_DESTROY=true, allowing (deliberate, reviewed override)"
  exit 0
fi
echo "check-plan: blocked. Review the plan; if intended, re-run with ALLOW_DESTROY=true (workflow_dispatch input allow_destroy)." >&2
exit 1
