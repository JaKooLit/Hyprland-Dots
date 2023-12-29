# #! /bin/bash

# --------------------Smooth bars animation with 1-2% increase in CPU usage -------------------
# bar="▁▂▃▄▅▆▇█"
# dict="s/;//g;"

# # creating "dictionary" to replace char with bar
# i=0
# while [ $i -lt ${#bar} ]
# do
#     dict="${dict}s/$i/${bar:$i:1}/g;"
#     i=$((i=i+1))
# done

# # write cava config
# config_file="/tmp/polybar_cava_config"
# echo "
# [general]
# bars = 10

# [output]
# method = raw
# raw_target = /dev/stdout
# data_format = ascii
# ascii_max_range = 7
# " > $config_file

# # read stdout from cava
# cava -p $config_file | while read -r line; do
#     echo $line | sed $dict
# done

# --------------------Optimized bars animation with 1-2% increase in CPU usage -------------------
bar="▁▂▃▄▅▆▇█"
dict="s/;//g"

# Calculate the length of the bar outside the loop
bar_length=${#bar}

# Create dictionary to replace char with bar
for ((i = 0; i < bar_length; i++)); do
    dict+=";s/$i/${bar:$i:1}/g"
done

# Create cava config
config_file="/tmp/polybar_cava_config"
cat >"$config_file" <<EOF
[general]
bars = 10

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

# Read stdout from cava and perform substitution in a single sed command
cava -p "$config_file" | sed -u "$dict"
