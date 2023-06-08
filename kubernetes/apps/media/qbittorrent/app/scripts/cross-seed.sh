#!/bin/bash

/usr/bin/curl -X POST \
    --data-urlencode "name=$1" \
    http://cross-seed.media.svc.cluster.local:2468/api/webhook
