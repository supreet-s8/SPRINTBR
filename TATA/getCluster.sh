#!/bin/bash

for i in `cat vips`
do
ssh -q $i "/opt/tms/bin/cli -t 'en' 'show cluster global'"
done
