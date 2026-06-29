#!/bin/bash
VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
MUTE=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c MUTED)

if [ "$MUTE" -eq 1 ]; then
    ICON="󰖁"
elif [ "$VOL" -lt 30 ]; then
    ICON="󰖀"
else
    ICON="󰕾"
fi

notify-send -c volume "$ICON" -h int:value:$VOL -t 1500 -h string:x-canonical-private-synchronous:volume
