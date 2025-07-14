#!/bin/zsh

# example: ./tag-all.zsh -t v2.2.2

# Helper function to print usage
usage() {
  echo "Usage: $0 -t <tag> [-m <message>] [-f] [repo1 repo2 ...]"
  echo ""
  echo "Options:"
  echo "  -t <tag>       Tag name (e.g. v2.2.2) [required]"
  echo "  -m <message>   Optional annotation message for the tag"
  echo "  -f             Force tagging even if working trees are dirty"
  echo ""
  echo "Positional arguments:"
  echo "  repo1 repo2 ...  Optional list of repositories to tag."
  echo "                   If omitted, defaults will be used."
  exit 1
}

# Parse options
FORCE=false
TAG=""
MSG=""

while getopts "t:m:f" opt; do
  case $opt in
    t) TAG=$OPTARG ;;
    m) MSG=$OPTARG ;;
    f) FORCE=true ;;
    *) usage ;;
  esac
done

shift $((OPTIND - 1))

# list of repo directories
SCRIPT_PATH="${(%):-%x}"
SCRIPT_DIR=$(cd "$(dirname "$SCRIPT_PATH")" && pwd)
# non-zsh variant: SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BASE_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
DEFAULT_REPOS=(
  "$BASE_DIR/umfeld"
  "$BASE_DIR/umfeld-arduino"
  "$BASE_DIR/umfeld-examples"
  "$BASE_DIR/umfeld-libraries"
)
REPOS=("${@:-${DEFAULT_REPOS[@]}}")

# Check if tag is set
if [[ -z "$TAG" ]]; then
  echo "❌ Error: Tag name is required."
  usage
fi

# Confirm tag creation
echo "🔖 Tagging all repositories with tag: $TAG"
[[ -n "$MSG" ]] && echo "Annotation message: \"$MSG\""
[[ "$FORCE" == true ]] && echo "⚠️  Force mode enabled – dirty working trees will not block tagging"

echo ""

# Loop through all repositories
for repo in "${REPOS[@]}"; do
  echo "📁 Entering repo: $repo"
  if [[ ! -d "$repo/.git" ]]; then
    echo "   ❌ Skipped: not a Git repo"
    continue
  fi

  cd "$repo" || continue

  # Check for dirty working tree
  if [[ "$FORCE" != true ]] && [[ -n "$(git status --porcelain)" ]]; then
    echo "   ⚠️  Skipped: working tree not clean. Use -f to override."
    cd -q > /dev/null
    continue
  fi

  # Check if tag already exists
  if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "   ❗ Tag '$TAG' already exists. Skipping tag creation."
  else
    if [[ -n "$MSG" ]]; then
      git tag -a "$TAG" -m "$MSG"
    else
      git tag "$TAG"
    fi
    echo "   ✅ Tag created: $TAG"
  fi

  # Push tag to origin
  git push origin --tags && echo "   🚀 Tags pushed to origin" || echo "   ❌ Push failed"

  cd -q > /dev/null
  echo ""
done

echo "Done tagging repositories."