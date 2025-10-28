#!/usr/bin/env zsh
set -euo pipefail

./create-arduino-examples.sh -o ../umfeld-arduino/examples/Basics -s ../umfeld-examples/Basics
./create-arduino-examples.sh -o ../umfeld-arduino/examples/Advanced -s ../umfeld-examples/Advanced
./create-arduino-examples.sh -o ../umfeld-arduino/examples/Audio -s ../umfeld-examples/Audio
./create-arduino-examples.sh -o ../umfeld-arduino/examples/Processing/Basics -s ../umfeld-examples/Processing/Basics
./create-arduino-examples.sh -o ../umfeld-arduino/examples/Processing/Topics -s ../umfeld-examples/Processing/Topics
