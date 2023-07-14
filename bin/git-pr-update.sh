#!/usr/bin/env bash

# Opens a single GitHub PR per commit, similar to Gerrit.

set -o pipefail
set -o errexit
set -o nounset

KEY="Change-Id: "
SOURCE_REMOTE=origin
TARGET_USER=$(git remote get-url "$SOURCE_REMOTE" | sed 's/^.*:\(.*\)\/.*$/\1/')

TARGET_REMOTE="${TARGET_REMOTE:-origin}"
if git rev-parse --verify main >/dev/null 2>&1; then
    DEFAULT_TARGET_BRANCH="main"
else
    DEFAULT_TARGET_BRANCH="master"
fi
TARGET_BRANCH="${TARGET_BRANCH:-${DEFAULT_TARGET_BRANCH}}"


function merge_base() {
    git fetch "${TARGET_REMOTE}"
    git merge-base "${TARGET_REMOTE}/${TARGET_BRANCH}" $1
}

function commit_summary() {
  git show --no-patch --format=%s ${1}
}

function commit_body() {
  git show --no-patch --format=%B ${1}
}

function pr_branch() {
  key_lines=$(commit_body ${1} | grep -E "^${KEY}")
  if [[ -z "${key_lines}" ]]; then
    echo "Sorry but commit ${commit} is missing \`$KEY\`" >&2
    echo ""  >&2
    echo "Try installing the Gerrit Git commit message hook and then amending your commits:"  >&2
    echo "" >&2
    echo " (cd ${repo} && f=`git rev-parse --git-dir`/hooks/commit-msg ; mkdir -p \$(dirname \$f) ; curl -Lo \$f https://gerrit-review.googlesource.com/tools/hooks/commit-msg ; chmod +x \$f)"  >&2
    echo "" >&2
    exit 1
  fi
  if [[ $(wc -l <<< "${key_lines}") -ne 1 ]]; then
    echo "commit ${1} has multiple lines starting with ${KEY}. Reword the commit message to fix." >&2
    exit 1
  fi
  offset=$((${#KEY} + 1))
  cut -c ${offset}- <<< "${key_lines}"
}

function reverse_lines() {
    if command -v tac >/dev/null 2>&1; then
        tac "$@"
    else
        awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }' "$@"
    fi
}

to=${2:-HEAD}
from=${1:-$(merge_base ${to})}

tail=$(git rev-parse ${from})
head=$(git rev-parse ${to})

git merge-base --is-ancestor ${tail} ${head}

repo=$(git rev-parse --show-toplevel)

commits=($(git rev-list --ancestry-path ${tail}..${head} | reverse_lines))

for commit in "${commits[@]}"; do
  if ! pr_branch ${commit} >/dev/null ; then
    exit 1
  fi
done

if ! command -v gh >/dev/null; then
  echo "GitHub not found. Try installing it from https://cli.github.com/, and then run `gh auth login`" >&2
  exit 1
fi

remotes=()
for commit in "${commits[@]}"; do
  remotes+=("${commit}:refs/heads/$(pr_branch $commit)")
done
git push $SOURCE_REMOTE --force-with-lease "${remotes[@]}"

i=0
for commit in "${commits[@]}"; do
  pr=$(pr_branch $commit)
  base=$( [[ $i -eq 0 ]] && echo "$TARGET_BRANCH" || echo "$(pr_branch ${commits[((i - 1))]})" )
  count=$(gh pr list --head "$pr" --json id --jq length)

  if [[ "$count" -gt 1 ]]; then
      echo "Sorry I don't know which PR to update."
      echo "There are multiple PRs with the same --head $pr"
      gh pr list --head "$pr"
      exit 1
  fi

  if [[ "$count" -eq 0 ]]; then
      gh pr create \
          --draft \
          --base "$base" \
          --head "${TARGET_USER}:${pr}" \
          --title "$(commit_summary $commit)" \
          --body  "$(commit_body $commit)" || true
  fi

  gh pr edit "${pr}" \
      --base "$base" \
      --title "$(commit_summary $commit)" \
      --body  "$(commit_body $commit)"

  if [[ -f ".pr-update.$i.sh" ]]; then
      bash ".pr-update.$i.sh" "$pr"
  fi

  ((++i))
done

echo "Done! 🦙🚀"
