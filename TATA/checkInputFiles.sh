#!/bin/bash

scp root@10.10.10.103:/data/missing_files /data/

if [ -s /data/missing_files ]
then
(echo "Subject: TCL-Guavus Missing Input Files";echo "From: tclmonitor@guavus.com";echo "To: tcl-delivery@guavus.com";echo "Content-Type: text/html";cat /data/missing_files)|/usr/lib/sendmail -t
fi
