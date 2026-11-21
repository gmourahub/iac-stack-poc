#!/usr/bin/env bash
# Deploys one instance of one stack: deploy.sh <stack-dir> <env> <plan|apply>
#   plan  -> init with the environment backend, write <env>.tfplan in the stack dir, then run the
#            destructive-change gate (check-plan.sh: fails on delete/replace unless ALLOW_DESTROY=true)
#   apply -> apply exactly that saved plan (run plan first, same commit and lock file; in CI the
#            plan file comes from the plan job's artifact)
# Credentials come from the environment (OIDC in CI, AWS_PROFILE locally). No secrets here.
set -euo pipefail

usage() {
  echo "usage: $0 <stack-dir> <env> <plan|apply>" >&2
  exit 2
}

[[ $# -eq 3 ]] || usage
stack_dir=$1
env=$2
action=$3

[[ -d $stack_dir ]] || { echo "error: stack dir '$stack_dir' not found" >&2; exit 2; }
[[ $env =~ ^[a-z][a-z0-9-]*$ ]] || { echo "error: invalid env '$env'" >&2; exit 2; }
[[ -f $stack_dir/environments/$env.tfvars ]] || { echo "error: $stack_dir has no environments/$env.tfvars" >&2; exit 2; }
[[ -f $stack_dir/environments/$env.s3.tfbackend ]] || { echo "error: $stack_dir has no environments/$env.s3.tfbackend" >&2; exit 2; }

plan_file="$env.tfplan"
tf() { terraform -chdir="$stack_dir" "$@"; }

case $action in
  plan)
    tf init -input=false -reconfigure -backend-config="environments/$env.s3.tfbackend"
    tf plan -input=false -var-file="environments/$env.tfvars" -out="$plan_file"
    plan_json=$(mktemp) # plan JSON holds sensitive values in clear text: keep it out of the repo
    trap 'rm -f "$plan_json"' EXIT
    tf show -json "$plan_file" >"$plan_json"
    "$(dirname "$0")/check-plan.sh" "$plan_json"
    ;;
  apply)
    [[ -f $stack_dir/$plan_file ]] || { echo "error: $stack_dir/$plan_file not found, run plan first" >&2; exit 2; }
    tf init -input=false -reconfigure -backend-config="environments/$env.s3.tfbackend"
    tf apply -input=false "$plan_file"
    ;;
  *)
    usage
    ;;
esac
