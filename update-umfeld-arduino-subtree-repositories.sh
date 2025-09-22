#!/bin/zsh
set -euo pipefail

echo "run script from 'umfeld-arduino' repository"

# config
UMF_PREFIX="umfeld/cores/sdl/umfeld"
UMF_SUBTREE="umfeld-upstream"
UMF_BRANCH="${UMF_BRANCH:-main}"   # allow override: UMF_BRANCH=dev ./update-umfeld-arduino-subtree-repositories.sh

# detect host repo + branch
UMF_REPO=$(git rev-parse --show-toplevel 2>/dev/null || true)
[[ -n "$UMF_REPO" ]] || { echo "error: run inside the host repo (umfeld-arduino)."; exit 1; }
cd "$UMF_REPO"
HOST_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# sanity: clean worktree
git diff --quiet && git diff --cached --quiet || { echo "error: commit or stash your changes first."; exit 1; }

# sanity: remote + branch exist
git remote get-url "$UMF_SUBTREE" >/dev/null

# avoid shallow pitfalls
if git rev-parse --is-shallow-repository | grep -qi true; then
  git fetch --unshallow || true
fi

# fetch upstream branch (skip tags to avoid clashes)
git fetch --no-tags "$UMF_SUBTREE" "$UMF_BRANCH" --prune

# prefix must exist (after your migration it should)
[[ -d "$UMF_PREFIX" ]] || { echo "error: prefix '$UMF_PREFIX' not found."; exit 1; }

# pull updates into subtree (unsquashed → bi-directional)
git subtree pull --prefix="$UMF_PREFIX" "$UMF_SUBTREE" "$UMF_BRANCH"

echo
printf "push host repo to origin/%s? [y/N] " "$HOST_BRANCH"
read -r ans
if printf '%s' "$ans" | grep -qi '^y'; then
  git push --follow-tags --force-with-lease origin "$HOST_BRANCH"
else
  echo "skipping host push."
fi

echo
printf "push subtree (%s) back to %s:%s? [y/N] " "$UMF_PREFIX" "$UMF_SUBTREE" "$UMF_BRANCH"
read -r ans2
if printf '%s' "$ans2" | grep -qi '^y'; then
  # one-liner (equivalent to split+push)
  git subtree push --prefix="$UMF_PREFIX" "$UMF_SUBTREE" "$UMF_BRANCH"
else
  echo "skipping subtree upstream push."
fi
