#!/usr/bin/env bash

echo "Cleaning subtitles for $1..."
python3 /add-ons/subcleaner/subcleaner.py "$1" -s

get_section () {
    if [[ "$1" = "/media/movies"* ]]; then
        echo "1"
    elif [[ "$1" == "/media/shows"* ]]; then
        echo "2"
    else
        echo "Unknown section: $1"
        exit 1
    fi
}

directory=$(dirname "$1")
section=$(get_section "$1")

echo "Refreshing Plex library for $directory..."
/usr/bin/curl -X PUT -G \
    --data-urlencode "path=$directory" \
    --data-urlencode "X-Plex-Token=$2" \
        http://plex.media.svc.cluster.local:32400/library/sections/$section/refresh
