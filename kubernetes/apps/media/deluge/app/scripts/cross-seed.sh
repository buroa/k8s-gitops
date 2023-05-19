#!/bin/bash

/usr/bin/curl -X POST \
    --data-urlencode "name=$2" \
    http://cross-seed.media.svc.cluster.local:2468/api/webhook
