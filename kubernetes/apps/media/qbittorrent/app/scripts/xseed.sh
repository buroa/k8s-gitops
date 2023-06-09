#!/bin/bash

/usr/bin/curl -X POST --data-urlencode "name=$1" http://localhost:2468/api/webhook
