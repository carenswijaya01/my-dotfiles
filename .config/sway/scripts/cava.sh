#! /bin/bash

# ------------------------------------------------------------------
# cava visualizer for waybar — port of polybar/scripts/cava.sh
# Same look: 20 bars, ▁▂▃▄▅▆▇█, raw ascii output (tail mode)
# ------------------------------------------------------------------

bar="▁▂▃▄▅▆▇█"
dict="s/;//g;"

# creating "dictionary" to replace char with bar
i=0
while [ $i -lt ${#bar} ]
do
    dict="${dict}s/$i/${bar:$i:1}/g;"
    i=$((i=i+1))
done

# write cava config
config_file="/tmp/cava_waybar_config"
cat > "$config_file" <<EOF
[general]
bars = 20

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

# read stdout from cava
cava -p "$config_file" | while read -r line; do
    echo "$line" | sed "$dict"
done
