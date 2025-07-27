# Media Stack NFS Configuration
#
# This file documents the centralized NFS configuration used across all media applications.
# To change the NFS server or path, update these values in each app's ks.yaml file.
#
# Current Configuration:
# NFS_SERVER: barbary.hypyr.space
# NFS_PATH: /mnt/data01/data
# Mount Point: /data (inside containers)
#
# Applications using these variables:
# - cross-seed
# - radarr
# - sonarr
# - sabnzbd
# - qbittorrent (and qbtools)
# - plex
# - bazarr
#
# Directory structure (following Trash Guides):
# /data/
# ├── torrents/
# │   ├── books/
# │   ├── movies/
# │   ├── music/
# │   └── tv/
# ├── usenet/
# │   ├── incomplete/
# │   └── complete/
# │       ├── books/
# │       ├── movies/
# │       ├── music/
# │       └── tv/
# └── media/
#     ├── books/
#     ├── movies/
#     ├── music/
#     └── tv/
#
# Benefits:
# - Hard links work between download and media directories
# - Atomic moves (instant, no copy operations)
# - Consistent paths across all applications
# - Single source of truth for NFS configuration
