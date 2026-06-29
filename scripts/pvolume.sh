#!/bin/bash
STEP=${2:-5}
CURRENT=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')

if [ "$1" = "up" ]; then
    TARGET=$((CURRENT + STEP))
    [ $TARGET -gt 100 ] && TARGET=100
else
    TARGET=$((CURRENT - STEP))
    [ $TARGET -lt 0 ] && TARGET=0
fi

STEPS=10
for i in $(seq 1 $STEPS); do
    VAL=$(echo "scale=2; $CURRENT + ($TARGET - $CURRENT) * $i / $STEPS" | bc)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ ${VAL}%
    sleep 0.008
done
