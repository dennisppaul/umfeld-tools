#!/bin/zsh
# Make a perfect byte-for-byte image of an SD card (macOS), then gzip it.
#
# Notes:
# - copies the ENTIRE card, exactly
# - destination cards must be >= source card size when cloning it back
# - script unmounts SDCard before imaging
# - script uses /dev/rdiskX (raw) for speed
# - on macOS device paths ( e.g SDCards, SSD, ... ) can found with `diskutil list physical`

set -euo pipefail

# --- Args ---------------------------------------------------------------------
if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <version-tag> <device path> <output dir>"
  echo "Example: $0 v1.0.0 /dev/disk18 ~/sd-backups"
  echo
  echo "Tip: Check your SD device with:  diskutil list physical"
  exit 1
fi

VERSION="$1"
SD_DEVICE="$2"
OUTPUT_DIR="${3%/}"
DATE_STR=$(date +%Y-%m-%d)
IMAGE_NAME="sd-${VERSION}-${DATE_STR}.img"
IMAGE_PATH="$OUTPUT_DIR/$IMAGE_NAME"
COMPRESSED_PATH="$IMAGE_PATH.gz"
CHECKSUM_PATH="$COMPRESSED_PATH.sha256"

# --- Preflight ----------------------------------------------------------------
if [[ ! -e "$SD_DEVICE" ]]; then
  echo "❌ Device $SD_DEVICE does not exist."
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Show card size and available disk space
disk_size=$(diskutil info "$SD_DEVICE" | sed -nE 's/^ *Disk Size: *([0-9]+(\.[0-9]+)?[[:space:]]*(GB|MB|TB)).*/\1/p')
printf "- SD Card Size    : %s\n" "$disk_size"

out_real=$(realpath "$OUTPUT_DIR")
read device mountpoint < <(df -P "$out_real" | awk 'NR==2 {print $1, $6}')
container_free=$(diskutil info "$device" | awk -F': *' '/Container Free Space/ { print $2; exit }')
container_free_short=${container_free%%\(*}; container_free_short=${container_free_short% }
printf "- Output Directory: %s (available)\n" "$container_free_short"

echo "⚠️  This will read the entire device $SD_DEVICE."
read "confirm?Proceed? (y/n): "
[[ "$confirm" == "y" ]] || { echo "Aborted."; exit 1; }

# --- Unmount & raw device ------------------------------------------------------
echo "Unmounting $SD_DEVICE..."
diskutil unmountDisk "$SD_DEVICE" || { echo "❌ Failed to unmount $SD_DEVICE"; exit 1; }

RAW_DEVICE="${SD_DEVICE/disk/rdisk}"

# --- Image (perfect copy) -----------------------------------------------------
start_time=$(date +%s)
echo "> Start: $(date +%Y-%m-%d\ %H:%M:%S)"
echo "Creating image from $RAW_DEVICE → $IMAGE_PATH ..."

# bs=4m is a good macOS choice; conv=sync to pad short reads; status=progress for feedback
sudo dd if="$RAW_DEVICE" of="$IMAGE_PATH" bs=4m status=progress conv=sync
sudo chown "$(id -u):$(id -g)" "$IMAGE_PATH"

# --- Compress & checksum -------------------------------------------------------
echo "Compressing image (gzip)..."
gzip -f "$IMAGE_PATH"

echo "Creating SHA-256 checksum..."
( cd "$OUTPUT_DIR" && shasum -a 256 "$(basename "$COMPRESSED_PATH")" > "$(basename "$CHECKSUM_PATH")" )

end_time=$(date +%s)
dur=$((end_time - start_time))
printf "> Done in %d min %d s\n" $((dur/60)) $((dur%60))

# --- Output --------------------------------------------------------------------
echo
echo "✅ Backup complete:"
echo "    Image   : $COMPRESSED_PATH"
echo "    SHA-256 : $CHECKSUM_PATH"
echo
echo "Verify:"
echo "    shasum -a 256 -c \"$CHECKSUM_PATH\""
echo
echo "Restore to another card (macOS):"
echo "    gzcat \"$COMPRESSED_PATH\" | sudo dd of=/dev/rdiskX bs=4m status=progress"
echo "    diskutil eject /dev/diskX"
echo
echo "Tip: The target card must be the same size or larger than the source for a perfect clone."
