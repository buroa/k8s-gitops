#!/bin/bash

talhelper genconfig

for i in {0..2}
do
   NAME="m$i"
   ENDPOINT="10.0.0.1$i"
   echo -n "$NAME - $ENDPOINT: "
   talosctl -n $ENDPOINT apply-config -f clusterconfig/k8s-$NAME*.yaml
done

for i in {0..2}
do
   NAME="w$i"
   ENDPOINT="10.0.0.2$i"
   echo -n "$NAME - $ENDPOINT: "
   talosctl -n $ENDPOINT apply-config -f clusterconfig/k8s-$NAME*.yaml
done