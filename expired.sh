#!/bin/bash
DEPLOYUMENT=$(az group list --query "[?tags.expires<=\`${timestamp}\`]".id -o tsv )
echo $DEPLOYUMENT
