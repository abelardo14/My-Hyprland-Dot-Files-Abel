#!/bin/bash
# Показывает активную раскладку клавиатуры через notify-send.
# Использование:
#   lang.sh current  — одноразовое уведомление о текущей раскладке
#   lang.sh listen   — слушать hyprland socket2 и уведомлять при каждом
#                      переключении раскладки (запускать из exec-once)

TAG="lang"
LANG_ICONS=("󰌌" "󰌎")   # EN RU  (Nerd Font nf-md-keyboard)
FALLBACK_ICONS=("EN" "RU")

find_socket2() {
	if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
		local short="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
		[ -S "$short" ] && { echo "$short"; return; }
	fi
	find /run/user/$(id -u)/hypr -name '.socket2.sock' 2>/dev/null | head -1
}

get_layout() {
	hyprctl devices -j | jq -r '
		.keyboards[]
		| select(.main == true)
		| .active_keymap'
}

notify_layout() {
	local keymap
	keymap=$(get_layout)
	local idx=0
	local lower
	lower=$(echo "$keymap" | tr '[:upper:]' '[:lower:]')
	case "$lower" in
		*russ*|*рус*) idx=1 ;;
	esac

	local icon="${LANG_ICONS[$idx]}"
	if [ "$icon" = "" ]; then
		icon="${FALLBACK_ICONS[$idx]}"
	fi

	notify-send -c "$TAG" "$icon $keymap" \
		-h string:x-canonical-private-synchronous:$TAG \
		-t 1000
}

case "${1:-current}" in
	listen)
		if ! command -v socat >/dev/null 2>&1; then
			echo "socat is required for 'listen' mode" >&2
			exit 1
		fi

		# ждём, пока Hyprland окончательно поднимет сокет и dbus-сессию
		sock=""
		for _ in $(seq 1 50); do
			sock=$(find_socket2)
			[ -n "$sock" ] && [ -S "$sock" ] && break
			sleep 0.1
		done
		if [ -z "$sock" ]; then
			echo "lang.sh: socket2.sock not found" >&2
			exit 1
		fi

		# пробуем подключиться к dbus (если exec-once стартует до пользовательской сессии)
		for _ in $(seq 1 30); do
			[ -n "$DBUS_SESSION_BUS_ADDRESS" ] && break
			if command -v dbus-update-activation-environment >/dev/null 2>&1; then
				dbus-update-activation-environment --systemd DBUS_SESSION_BUS_ADDRESS >/dev/null 2>&1
			fi
			sleep 0.2
		done

		# реентерабельная защита: чтобы повторные вызовы не плодили процессы
		# исключаем свой PID, чтобы pkill не убил самого себя
		others=$(pgrep -f 'hypr/scripts/lang\.sh listen' | grep -v "^$$" || true)
		if [ -n "$others" ]; then
			kill $others 2>/dev/null
			sleep 0.2
		fi

		socat -U - "UNIX-CONNECT:$sock" 2>/dev/null \
		| while IFS= read -r line; do
			if [[ "$line" == activelayout\>\>* ]]; then
				notify_layout
			fi
		done
		;;
	current|*)
		notify_layout
		;;
esac