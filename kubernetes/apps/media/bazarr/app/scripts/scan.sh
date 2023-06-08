#!/usr/bin/env bash

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

section=$(get_section "$1")

/usr/bin/curl -X POST -G \
    -d path=$(dirname "$1") \
    -d X-Plex-Token="$2" \
        "http://plex.media.svc.cluster.local:32400/library/sections/$section/refresh"
