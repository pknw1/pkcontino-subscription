#!/bin/bash
timestamp=$(date -u +%d/%m/%Y)

DEPLOYUMENT=$(az group list --query "[?tags.expires<=\`${timestamp}\`]".id -o tsv )
echo $DEPLOYUMENT 