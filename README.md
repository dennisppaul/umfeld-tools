# Umfeld Tools

a set of tools for the [Umfeld](https://github.com/dennisppaul/umfeld) project.

```
.
├── discover-libs.sh
├── LICENSE
├── merge-branch.sh
├── raspberry-pi
│   ├── clean-raspberry-pi.sh
│   ├── create-image-macOS.sh
│   ├── PiShrink
│   └── README.md
└── tag-repositories.sh
```

- `discover-libs.sh` :: this script tries to gather information about a package or library to be used in the main *Umfeld* Cmake build script. example usage: `./discover-libs.sh SDL3`
- `merge-branch.sh` :: this script merges a ( development ) branch into the main branch. usage example: `./merge-branch.sh main dev-discover-packages`
- `raspberry-pi` :: this folder contains a series of scripts used to create a clean and small RPI image. usage example: `./create-image-macOS.sh v2.3.0 /dev/disk14 ~/Desktop/`
- `tag-repositories.sh` :: this script tags all 4 umfeld examples. usage example: `./tag-all.zsh -t v2.2.2`
