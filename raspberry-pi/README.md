# Umfeld Tools / Raspberry Pi

this is an example workflow of generating an ISO image:

- clone [umfeld-tools](https://github.com/dennisppaul/umfeld-tools) repository from github
- clean installation in terminal on RPI: `./umfeld-tools/raspberry-pi/clean-raspberry-pi.sh`
- clear history: `history -c`
- shutdown RPI: `sudo shutdown now`
- insert SD into macOS machine
- start `docker`
- create ISO image e.g: `./create-image-macOS.sh v2.2.0 /dev/disk14 /tmp`
- use e.g `Raspberry Pi Imager` to clone system onto SD card

## Profiling

duration to create an ISO image:

| SYSTEM           | OS                 | SD CARD                 | DURATION  | SIZE   |
| ---------------- | ------------------ | ----------------------- | --------- | ------ |
| MacBook Pro (M3) | RPI OS Lite, 64bit | SAMSUNG ( 8GB )         | 07:30 min | 1.13GB |
| MacBook Pro (M3) | RPI OS, 64bit      | SAMSUNG ( 8GB )         | 08:05 min | 2.62GB |
| MacBook Pro (M3) | RPI OS Lite, 64bit | Scandisk Ultra ( 32GB ) | 09:40 min | 1.13GB |

example time splits on a MacBook Pro (M3) with Scandisk Ultra ( 32GB ):

```
  386sec :: creating image ( at 84MB/s )
+  33sec :: skrinking image ()
+ 161sec :: compressing image
= 580sec ( 09:40 )
```

## ISO Image Naming Convention

- `umfeld-v2.2.0-2025-06-28-raspios-bookworm-arm64-2025-05-13.img.gz` :: image of *Umfeld* with version v2.2.0 created on 2025-06-28, based on Raspberry Pi OS 64-bit ( Bookworm ) released on 2025-05-13
- `umfeld-v2.2.0-2025-06-28-raspios-lite-bookworm-arm64-2025-05-13.img.gz` :: same as above only for the lite version of Raspberry Pi OS ( i.e no windowing system like X11 or wayland )
