#!/bin/bash
timestamp=$(date -u +%d/%m/%Y)

DEPLOYMENT=$(az group list --query "[?tags.expires<=\`${timestamp}\`]".id -o tsv | head -n1 |awk -F/ '{print $NF}')
echo $DEPLOYMENT 