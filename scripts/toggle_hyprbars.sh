#!/bin/bash
current=$(hyprctl getoption plugin:hyprbars:bar_height | awk 'NR==1{print $2}')
if [ "$current" = "0" ]; then
    hyprctl keyword plugin:hyprbars:bar_height 25
else
    hyprctl keyword plugin:hyprbars:bar_height 0
fi
