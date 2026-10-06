#!/usr/bin/env bash
# Each fixture runs alone; good-skill must pass, every other fixture must fail with its reason.
set -uo pipefail
cd "$(dirname "$0")/.."
status=0
expect() { # fixture, expected exit, expected substring
  work=$(mktemp -d); cp -r "tests/fixtures/$1" "$work/"
  out=$(scripts/check-skills.sh "$work" --neutral 2>&1); code=$?; rm -rf "$work"
  if [[ $code -ne $2 || "$out" != *"$3"* ]]; then echo "TEST FAIL $1: exit $code, output: $out"; status=1; else echo "ok $1"; fi
}
expect good-skill 0 ""
expect bad-name   1 "name field must equal directory name"
expect extra-key  1 "non-spec frontmatter keys: disable-model-invocation"
expect too-long   1 "max 300"
expect stack-leak 1 "stack-specific term"
expect line-ref   1 "forbidden pattern"
expect ref-pointer 0 ""
expect yaml-colon 1 "quote the value"
expect stack-leak-desc 1 "stack-specific term"
expect stack-leak-case 1 "stack-specific term"
exit $status
