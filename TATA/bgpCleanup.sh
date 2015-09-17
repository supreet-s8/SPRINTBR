#!/bin/bash

ip="10.10.10.201"

ssh -q root@$ip "find /data/routing/bgp/ -mtime +5 -exec ls -lrt {} \;"
