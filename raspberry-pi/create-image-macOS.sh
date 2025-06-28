#!/bin/zsh

# NOTE requires about 12min on MacBook Pro M3

# Check for arguments
if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
  echo "Usage: $0 <version-tag> <device path> <output directory>"
  echo "Example: $0 v2.2.0 /dev/disk4 ~/rpi-backups"
  
  for dev in $(diskutil list | awk '/^\/dev\/disk/ {print $1}'); do
    # Pull out the “Device / Media Name” line, trim whitespace
    media_name=$(diskutil info "$dev" \
      | awk -F: '/Device \/ Media Name/ { gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2); print $2 }')
  
    # Match “Built-In SDXC Reader” or “Built In SDXC Reader” (case-insensitive)
    if [[ "$media_name" =~ ^[Bb]uilt([- ]In[[:space:]]*SDXC[[:space:]]*Reader)$ ]]; then
      echo "> "
      echo "> it looks like the SD Card reader has device path:"
      echo "> "
      echo ">     $dev"
      echo "> "
      echo "> alternatively, use 'Disk Utitily.app' to find SD Card reader."
      echo "> "
    fi
  done
  
  exit 1
fi

# Parse parameters
VERSION="$1"
SD_DEVICE="$2"
OUTPUT_DIR="${3%/}"      # strip trailing slash if any
DATE_STR=$(date +%Y-%m-%d)
IMAGE_NAME="umfeld-${VERSION}-rpi-$DATE_STR.img"
IMAGE_PATH="$OUTPUT_DIR/$IMAGE_NAME"
COMPRESSED_PATH="$IMAGE_PATH.gz"
PISHRINK_REPO_DIR="$OUTPUT_DIR/PiShrink"
PISHRINK_IMAGE="pishrink:latest"

# Check if Docker is running or installed
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker CLI not found. Please install Docker."
  exit 1
elif ! docker info >/dev/null 2>&1; then
  echo "❌ Docker is not running or you don't have permission ..."
  echo "    ... if you are on macOS try starting 'Docker.app'."
  echo "    ... if you are on Linux try 'sudo systemctl start docker' or check your user group."
  echo "    ... if you are on Windows ... good luck ;)"
  exit 1
fi

# Check if device exists
if [[ ! -e "$SD_DEVICE" ]]; then
  echo "❌ Device $SD_DEVICE does not exist."
  exit 1
fi

# show SD card size ...
disk_size=$(diskutil info "$SD_DEVICE" | sed -nE 's/^ *Disk Size: *([0-9]+(\.[0-9]+)?[[:space:]]*(GB|MB|TB)).*/\1/p')
size_value=${disk_size% *}
size_unit=${disk_size#* }
required=$(awk "BEGIN{printf \"%.1f\", $size_value*2}")
printf "- SD Card Size    : %s\n" "$disk_size"
# ... and available disk space
file=$(realpath $OUTPUT_DIR)
read device mountpoint < <(df -P "$file" | awk 'NR==2 {print $1, $6}')
container_free=$(diskutil info "$device" | awk -F': *' '/Container Free Space/ { print $2; exit }')
container_free_short=${container_free%%\(*}
container_free_short=${container_free_short% }
printf "- Output Directory: $container_free_short (available)\n"
printf "Image creation may require up to %s %s free space\n" "$required" "$size_unit"

# Confirm with user
echo "⚠️  This will create a full image of $SD_DEVICE"
read "confirm?Are you sure this is correct? (y/n): "
if [[ "$confirm" != "y" ]]; then
  echo "Aborted."
  exit 1
fi

# Start timer
start_time=$(date +%s)
echo "> Start time: $(date +%Y-%m-%d\ %H:%M:%S)"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Unmount partitions (macOS-specific)
echo "Unmounting $SD_DEVICE..."
diskutil unmountDisk "$SD_DEVICE" || {
  echo "❌ Failed to unmount $SD_DEVICE. Abort."
  exit 1
}

# Switch to raw device for speed
RAW_DEVICE="${SD_DEVICE/disk/rdisk}"

# Create image
echo "Creating image from $RAW_DEVICE..."
sudo dd if="$RAW_DEVICE" of="$IMAGE_PATH" bs=4m status=progress conv=sync
sudo chown "$(id -u):$(id -g)" "$IMAGE_PATH"

# === PiShrink via Docker on macOS ===

# 1. Check Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker is required for PiShrink on macOS. Please install Docker Desktop and try again."
  exit 1
fi

# 2. Clone PiShrink repo if needed
if [[ ! -d "$PISHRINK_REPO_DIR" ]]; then
  echo "🔍 Cloning PiShrink into $PISHRINK_REPO_DIR..."
  git clone https://github.com/Drewsif/PiShrink.git "$PISHRINK_REPO_DIR"
fi

# 3. Build the Docker image if not already present
if ! docker image inspect "$PISHRINK_IMAGE" >/dev/null 2>&1; then
  echo "🛠  Building PiShrink Docker image..."
  docker build -t "$PISHRINK_IMAGE" "$PISHRINK_REPO_DIR"
fi

# 4. Run PiShrink (in-place) from within $OUTPUT_DIR
echo "✂️  Shrinking image with PiShrink (Docker)..."
pushd "$OUTPUT_DIR" >/dev/null
docker run --rm --privileged -v "$(pwd)":/workdir:rw "$PISHRINK_IMAGE" -vr "$IMAGE_NAME" || {
  echo "❌ PiShrink failed. Proceeding with unshrunk image."
}
popd >/dev/null

# === End PiShrink integration ===

# Compress image
echo "Compressing image..."
gzip "$IMAGE_PATH"

# End timer
end_time=$(date +%s)
echo "> End time  : $(date +%Y-%m-%d\ %H:%M:%S)"

duration=$((end_time - start_time))
minutes=$((duration / 60))
seconds=$((duration % 60))
printf "> Duration  : %d minutes and %d seconds\n" "$minutes" "$seconds"

# Done
echo "✅ Backup complete: $COMPRESSED_PATH"
echo "You can now flash it using Raspberry Pi Imager or:"
echo "    sudo dd if=$COMPRESSED_PATH of=/dev/rdiskX bs=4m"
