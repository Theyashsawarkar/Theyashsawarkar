#!/usr/bin/env bash
# Makes github.com/Theyashsawarkar match profile.json: bio, company,
# location, website, X handle, hireable, the social links, and checks the
# pinned repos. Uses your gh login (needs the "user" scope).
#
#   tools/apply-profile.sh          apply what differs
#   tools/apply-profile.sh --check  list what differs, exit 1 if anything does
#
# Pins can't be set through GitHub's API: they're only reported here. Set
# them on the profile page (Customize your pins) in the order listed.
set -euo pipefail
cd "$(dirname "$0")/.."
check=false
[ "${1:-}" = "--check" ] && check=true
cfg=profile.json
n=0
differs() { n=$((n + 1)); echo "differs: $1"; }

# Profile fields: one PATCH with everything that differs.
live=$(gh api user)
patch='{}'
for k in $(jq -r '.user | keys[]' "$cfg"); do
  want=$(jq -c --arg k "$k" '.user[$k]' "$cfg")
  have=$(jq -c --arg k "$k" '.[$k]' <<<"$live")
  if [ "$want" != "$have" ]; then
    differs "$k: $have -> $want"
    patch=$(jq -c --arg k "$k" --argjson v "$want" '. + {($k): $v}' <<<"$patch")
  fi
done
if ! $check && [ "$patch" != '{}' ]; then
  gh api -X PATCH user --input - <<<"$patch" >/dev/null && echo "updated profile fields"
fi

# Social links: add the missing ones, remove the ones not in the config.
mapfile -t want_social < <(jq -r '.social_accounts[]' "$cfg")
mapfile -t have_social < <(gh api user/social_accounts --jq '.[].url')
add=() del=()
for u in "${want_social[@]}"; do printf '%s\n' "${have_social[@]}" | grep -qxF "$u" || add+=("$u"); done
for u in "${have_social[@]}"; do printf '%s\n' "${want_social[@]}" | grep -qxF "$u" || del+=("$u"); done
for u in "${del[@]}"; do differs "social link to remove: $u"; done
for u in "${add[@]}"; do differs "social link to add: $u"; done
if ! $check; then
  if [ "${#del[@]}" -gt 0 ]; then
    jq -n '{account_urls: $ARGS.positional}' --args "${del[@]}" | gh api -X DELETE user/social_accounts --input - >/dev/null
    echo "removed ${#del[@]} social link(s)"
  fi
  if [ "${#add[@]}" -gt 0 ]; then
    jq -n '{account_urls: $ARGS.positional}' --args "${add[@]}" | gh api -X POST user/social_accounts --input - >/dev/null
    echo "added ${#add[@]} social link(s)"
  fi
fi

# Pins: report only.
want_pins=$(jq -r '.pins | join(" ")' "$cfg")
have_pins=$(gh api graphql -f query='{ viewer { pinnedItems(first: 6, types: REPOSITORY) { nodes { ... on Repository { name } } } } }' \
  --jq '[.data.viewer.pinnedItems.nodes[].name] | join(" ")')
if [ "$want_pins" != "$have_pins" ]; then
  differs "pins: [$have_pins] -> [$want_pins] (set by hand: Customize your pins on the profile page)"
fi

if [ "$n" -eq 0 ]; then echo "profile matches profile.json"; fi
if $check; then [ "$n" -eq 0 ]; exit; fi
