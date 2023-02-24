#!/bin/bash

sed -i 's/dl-cdn.alpinelinux.org/mirror.clarkson.edu/g' /etc/apk/repositories

echo "**** installing nodejs + git ****"
apk add --update nodejs npm git

echo "**** installing qbit-race ****"
rm -rf /config/qbit-race
git clone https://github.com/buroa/qbit-race.git /config/qbit-race && \
  cd /config/qbit-race && \
  npm install . && \
  npm link