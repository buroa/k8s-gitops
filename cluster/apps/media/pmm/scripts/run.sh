#!/usr/bin/env bash

echo "*** running pmm - movies ***"
python3 plex_meta_manager.py \
    --run \
    -cache-libraries \
    --read-only-config \
    --run-libraries "Movies"

echo "*** running pmm - tv shows ***"
python3 plex_meta_manager.py \
    --run \
    --cache-libraries \
    --read-only-config \
    --run-libraries "TV Shows"