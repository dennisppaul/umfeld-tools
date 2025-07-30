#!/usr/bin/env bash

# Parse optional --target flag
TARGET_NAME=""
while [[ "$1" == --* ]]; do
    case "$1" in
        --target=*) TARGET_NAME="${1#--target=}"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Check library argument
if [ -z "$1" ]; then
    echo "Usage: discover-lib [--target=MyTarget] <library-name>"
    exit 1
fi

LIB="$1"
UPPER_LIB=$(echo "$LIB" | tr '[:lower:]' '[:upper:]')

echo "📦 Discovering library info for: $LIB"
echo

# === find_package name ===
FIND_PACKAGE_NAME="$LIB"
echo "🔎 FIND_PACKAGE_NAME: $FIND_PACKAGE_NAME"

# === pkg-config ===
PKG_CONFIG_NAME=$(pkg-config --list-all 2>/dev/null | awk -v lib="$LIB" 'BEGIN{IGNORECASE=1} $1 ~ lib { print $1; exit }')
if [ -z "$PKG_CONFIG_NAME" ]; then
    PKG_CONFIG_NAME="$LIB"
fi
echo "🔎 PKG_CONFIG_NAME: $PKG_CONFIG_NAME"

# === guess manual lib name ===
MANUAL_LIB_NAME=$(find /usr/local/lib /opt/homebrew/lib /usr/lib -type f -name "lib$LIB*.a" -o -name "lib$LIB*.so" -o -name "lib$LIB*.dylib" 2>/dev/null | sed 's:.*/lib::;s:\..*::' | sort -u | head -n 1)
MANUAL_LIB_NAME=${MANUAL_LIB_NAME:-$LIB}
echo "📚 MANUAL_LIB_NAMES: $MANUAL_LIB_NAME"

# === guess header ===
MANUAL_HEADER_NAME=$(find /usr/local/include /opt/homebrew/include /usr/include -type f -iname "*$LIB*.h" 2>/dev/null | sed 's:^.*include/::' | sort -u | head -n 1)
MANUAL_HEADER_NAME=${MANUAL_HEADER_NAME:-"$LIB.h"}
echo "📁 MANUAL_HEADER_NAME: $MANUAL_HEADER_NAME"
echo

# === target name ===
TARGET_LINE=""
if [ -n "$TARGET_NAME" ]; then
    TARGET_LINE="$TARGET_NAME"
else
    TARGET_LINE="\${PROJECT_NAME}"
fi

# === suggested target ===
MODERN_TARGET="${LIB}::${LIB}"

# === print complete discover_library() call ===
echo "✅ Suggested discover_library() call:"
echo
cat <<EOF
discover_library(
    $TARGET_LINE
    $FIND_PACKAGE_NAME
    $MODERN_TARGET
    $PKG_CONFIG_NAME
    $UPPER_LIB
    "$MANUAL_LIB_NAME"
    "$MANUAL_HEADER_NAME"
    PRIVATE
)
EOF
