#!/usr/bin/env bash
# Usage: scripts/check-skills.sh <skills-dir> [--neutral]
# Checks agentskills frontmatter, size limits and forbidden content.
# --neutral also rejects stack-specific terms in SKILL.md bodies (generic skills only).
set -euo pipefail
dir=${1:?usage: check-skills.sh <skills-dir> [--neutral]}
neutral=${2:-}
patterns="$(dirname "$0")/forbidden-patterns.txt"
fail=0
err() { echo "FAIL: $*"; fail=1; }

for skill in "$dir"/*/; do
  name=$(basename "$skill")
  file="$skill/SKILL.md"
  [[ -f $file ]] || { err "$name: missing SKILL.md"; continue; }
  [[ $(head -1 "$file") == "---" ]] || { err "$name: missing frontmatter"; continue; }
  fm=$(awk 'NR==1{next} /^---$/{exit} {print}' "$file")
  body=$(awk '/^---$/{c++; next} c>=2{print}' "$file")
  desc=$(grep -E '^description:' <<<"$fm" || true)

  grep -qE "^name: ${name}\$" <<<"$fm" || err "$name: name field must equal directory name"
  grep -qE '^description: "?Use when' <<<"$fm" || err "$name: description must start with 'Use when'"
  extra=$(grep -oE '^[a-z][a-z_-]*:' <<<"$fm" | tr -d ':' \
    | grep -vxE 'name|description|license|compatibility|metadata|allowed-tools' | paste -sd, - || true)
  [[ -z $extra ]] || err "$name: non-spec frontmatter keys: $extra"
  # A plain YAML scalar cannot contain ': ' or ' #'; parsers reject the whole frontmatter.
  plain=$(grep -E '^[a-z][a-z_-]*: [^"'"'"'|>]' <<<"$fm" | grep -E '^[^:]*: .*(: | #)' || true)
  [[ -z $plain ]] || err "$name: unquoted value contains ': ' or ' #', quote the value: $plain"

  lines=$(wc -l <"$file" | tr -d ' ')
  (( lines <= 300 )) || err "$name: SKILL.md has $lines lines (max 300)"
  for ref in "$skill"references/*.md; do
    [[ -e $ref ]] || continue
    rl=$(wc -l <"$ref" | tr -d ' ')
    (( rl <= 400 )) || err "$name: references/$(basename "$ref") has $rl lines (max 400)"
  done

  if [[ $neutral == --neutral ]]; then
    # Pointers like references/jest.md are allowed; the term itself in prose is not.
    hit=$(sed -E 's#references/[A-Za-z0-9_-]+\.md##g' <<<"$desc"$'\n'"$body" \
      | grep -nwiE 'mix|npm|npx|jest|ExUnit|Mox|pytest|go test|vitest|gomock|testify|cargo|cypress' | head -3 || true)
    [[ -z $hit ]] || err "$name: stack-specific term in description or body (move to references/): $hit"
  fi
done

if hits=$(grep -rnEf "$patterns" "$dir"); then
  while IFS= read -r h; do err "forbidden pattern: $h"; done <<<"$hits"
fi
exit $fail
