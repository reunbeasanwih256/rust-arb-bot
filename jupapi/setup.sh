#!/bin/bash

MINTS=$(cat /app/mints.json | jq -r '.[]' | tr '\n' ',' | sed 's/,$//');

export FILTER_MARKETS_WITH_MINTS=$MINTS;

wget --no-cache --no-cookies -O /app/markets.json https://cache.jup.ag/markets?v=4

chmod +x /app/jupiter-swap-api;

cd /app && ./jupiter-swap-api
