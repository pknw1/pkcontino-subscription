#!/bin/bash
timestamp=$(date -u +%d/%m/%Y)

DEPLOYUMENT=$(az group list --query "[?tags.expires<=\`${timestamp}\`]".id -o tsv | head -n1 |awk -F '{print $NF}')
echo $DEPLOYUMENT 