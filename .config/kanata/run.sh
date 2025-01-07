#!/bin/bash

kanata -c ~/.config/kanata/minidox.kbd -p 1025 &
sleep 5
conky -c ~/.config/conky/minidox.conf &
cat </dev/tcp/127.0.0.1/1025 | { while read line; do layer=$(echo $line | jq -rMc .LayerChange.new); ln -sf ~/.config/conky/minidox_layouts/$layer ~/.config/conky/current_keyboard_layout; done; }
