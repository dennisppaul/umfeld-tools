#!/usr/bin/env zsh
set -euo pipefail

print_usage(){
  echo "Usage: $0 -o <output_dir> -s <source_dir> [-s <source_dir> ...]"
  echo "Example: $0 -o ./ArduinoExamples -s ./Advanced -s ./Audio"
}

typeset -a SOURCES
OUTDIR=""

while getopts "s:o:h" opt; do
  case "$opt" in
    s) SOURCES+=("$OPTARG");;
    o) OUTDIR="$OPTARG";;
    h) print_usage; exit 0;;
    *) print_usage; exit 1;;
  esac
done

if [[ -z "${OUTDIR:-}" || ${#SOURCES[@]} -eq 0 ]]; then
  print_usage
  exit 1
fi

mkdir -p "$OUTDIR"

for SRC in "${SOURCES[@]}"; do
  if [[ ! -d "$SRC" ]]; then
    echo "Skipping non-directory source: $SRC" >&2
    continue
  fi

  # Find all application.cpp files, skipping build directories
  while IFS= read -r -d '' APPFILE; do
    EXAMPLE_DIR="$(dirname "$APPFILE")"
    EXAMPLE_NAME="$(basename "$EXAMPLE_DIR")"

    # Compute path relative to source to mirror structure in OUTDIR
    case "$EXAMPLE_DIR" in
      "$SRC") RELDIR="";;
      *) RELDIR="${EXAMPLE_DIR#$SRC/}";;
    esac
    TARGET_DIR="$OUTDIR/${RELDIR}"
    mkdir -p "$TARGET_DIR"

    # Copy everything except unwanted files and build directories
    rsync -a \
      --exclude 'application.cpp' \
      --exclude 'CMakeLists.txt' \
      --exclude 'build/' \
      --exclude 'cmake-build-debug/' \
      --exclude 'cmake-build-release/' \
      "$EXAMPLE_DIR/" "$TARGET_DIR/"

    cp "$APPFILE" "$TARGET_DIR/$EXAMPLE_NAME.ino"

    echo "Converted: $APPFILE -> $TARGET_DIR/$EXAMPLE_NAME.ino"
  done < <(find "$SRC" -type f -name 'application.cpp' \
    -not -path '*/build/*' \
    -not -path '*/application-bundle-macOS/*' \
    -not -path '*/capture/*' \
    -not -path '*/movie/*' \
    -not -path '*/graphics-terminal/*' \
    -not -path '*/cmake-build-debug/*' \
    -not -path '*/cmake-build-release/*' -print0)
done

echo "Done. Output at: $OUTDIR"
