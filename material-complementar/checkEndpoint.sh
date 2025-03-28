#!/bin/bash

URL="http://localhost:30000"

while true; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

  if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $URL está acessível (HTTP $HTTP_CODE)"
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $URL não está acessível (HTTP $HTTP_CODE)"
  fi

  sleep 1
done
