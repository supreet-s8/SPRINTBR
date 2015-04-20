#!/bin/bash

# ---------------------------------------------------
# This is the path where the Guavus Tools set exists
# This is ideally located at /data/scripts
# Update the path if required

TOOLSPATH='/data/CMDS'
# ---------------------------------------------------



# -- Do not edit --

cd $TOOLSPATH/GuavusTools/bin/
echo -e " --- \033[1m`hostname`\033[0m STATUS REPORT ON \033[1m`date`\033[0m ---"
echo "  HADOOP REPORT"
$TOOLSPATH/GuavusTools/bin/dfsReport.pl 2>/dev/null
echo "  SYSTEM REPORT"
$TOOLSPATH/GuavusTools/bin/checkCollectorState.pl; echo
echo "  INPUT DATA REPORT"
$TOOLSPATH/GuavusTools/bin/verifyInputStream.pl;
echo "  COLLECTOR FILES CHECK"
$TOOLSPATH/GuavusTools/bin/verifyCollectorFiles.sh
echo "  CHECK SAP/NAP HDFS Reachability"
$TOOLSPATH/GuavusTools/bin/verifyNECReachability.sh
echo " --- END OF REPORT ---"

