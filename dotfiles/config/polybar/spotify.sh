#!/bin/bash
domain="org.mpris.MediaPlayer2"
path="/org/mpris/MediaPlayer2"
cmd="org.freedesktop.DBus.Properties.Get"

getTitle() {
    meta=$(dbus-send --print-reply --dest=${domain}.spotify ${path} ${cmd} string:${domain}.Player string:Metadata)

    artist=$(echo "$meta" | sed -nr '/xesam:artist"/,+2s/^ +string "(.*)"$/\1/p' | tail -1)
    album=$(echo "$meta" | sed -nr '/xesam:album"/,+2s/^ +variant +string "(.*)"$/\1/p' | tail -1)
    title=$(echo "$meta" | sed -nr '/xesam:title"/,+2s/^ +variant +string "(.*)"$/\1/p' | tail -1)

    if isPlaying; then
      if ! pgrep -x spotify >/dev/null; then
        echo ""; exit
      fi

            echo "$title: $artist - $album"
    else
      echo "  - $title: $artist - $album"
    fi
}

isPlaying() {
  status=$(dbus-send --print-reply --dest=${domain}.spotify ${path} ${cmd} string:${domain}.Player string:PlaybackStatus \
    | tail -1 \
    | sed 's/^.*"\(.*\)".*/\1/')
  if [ "${status}" = "Paused" ]; then
    return 1
  fi
  return 0
}

togglePlay() {
  dbus-send --print-reply --dest=${domain}.spotify ${path} ${domain}.Player.PlayPause
}

case "$1" in
        --title)
                getTitle
        ;;
        --togglePlay)
                togglePlay
        ;;
        --isPlaying)
                isPlaying
        ;;
esac
