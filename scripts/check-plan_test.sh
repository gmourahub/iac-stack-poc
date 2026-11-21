#!/usr/bin/env bash
# Tests for check-plan.sh against hand-written plan JSON fixtures. Needs jq. Run: scripts/check-plan_test.sh
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
check="$here/check-plan.sh"
data="$here/testdata"
failures=0

expect() { # expect <exit-code> <description> <command...>
  local want=$1 desc=$2 got
  shift 2
  "$@" >/dev/null 2>&1
  got=$?
  if [[ $got -eq $want ]]; then echo "ok   $desc"; else echo "FAIL $desc (exit $got, want $want)"; failures=$((failures + 1)); fi
}

expect 0 "create/update/no-op passes" env -u ALLOW_DESTROY "$check" "$data/plan-safe.json"
expect 0 "plan without resource_changes passes" env -u ALLOW_DESTROY "$check" "$data/plan-empty.json"
expect 1 "delete and replace are blocked" env -u ALLOW_DESTROY "$check" "$data/plan-destroy.json"
expect 1 "ALLOW_DESTROY other than true still blocks" env ALLOW_DESTROY=yes "$check" "$data/plan-destroy.json"
expect 0 "ALLOW_DESTROY=true allows" env ALLOW_DESTROY=true "$check" "$data/plan-destroy.json"
expect 2 "missing file is an error" "$check" "$data/does-not-exist.json"
expect 2 "non-plan input is an error" "$check" "$here/check-plan.sh"
expect 2 "no argument is an error" "$check"

out=$(env -u ALLOW_DESTROY "$check" "$data/plan-destroy.json" 2>/dev/null)
if [[ $out == *"delete,create	aws_db_instance.main"* && $out == *"delete	aws_sns_topic.old"* && $out != *aws_sqs_queue* ]]; then
  echo "ok   lists only the deleted/replaced addresses"
else
  echo "FAIL listed addresses: $out"; failures=$((failures + 1))
fi

[[ $failures -eq 0 ]] || { echo "$failures test(s) failed"; exit 1; }
echo "all tests passed"
