#!/bin/bash
set -e

if [ "$1" = 'passenger-start' ]; then
  echo 'Starting passenger'
  passenger start
fi

exec "$@"