#!/usr/bin/env bash

/usr/bin/curl -sG -X POST --data-urlencode "dir=$1" -o - -I http://autoscan.media.svc.cluster.local:3030/triggers/manual