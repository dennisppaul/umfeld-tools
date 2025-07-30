#!/usr/bin/env bash

# Usage: ./merge-branch.sh <main-branch> <dev-branch>
# Example: cd ../umfeld                                     # switch to the repo you want to merge in
#          ../umfeld-tools/merge-branch.sh main dev-feature # run the script from there
#
# note, the script must be run from within the repository directory.

set -e  # exit on any error

# --- 1. argument check ---
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <main-branch> <dev-branch>"
  exit 1
fi

MAIN_BRANCH=$1
DEV_BRANCH=$2

# --- 2. check we're in a git repo ---
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "Error: Not inside a Git repository."
  exit 1
fi

# --- 3. checkout dev and check for clean working tree ---
git checkout "$DEV_BRANCH"

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: Uncommitted changes on $DEV_BRANCH. Please commit or stash them first."
  exit 1
fi

# --- 4. checkout main and merge ---
git checkout "$MAIN_BRANCH"
git merge "$DEV_BRANCH"

# --- 5. push main ---
git push origin "$MAIN_BRANCH"

# --- 6. confirm before deleting dev branch ---
echo
read -p "Delete local and remote branch '$DEV_BRANCH'? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  git branch -d "$DEV_BRANCH"
  git push origin --delete "$DEV_BRANCH"
  echo "Branch '$DEV_BRANCH' deleted locally and remotely."
else
  echo "Skipped deleting '$DEV_BRANCH'."
fi

echo
echo "✅ Merge complete."
