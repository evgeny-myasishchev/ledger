#!/bin/bash
set -e

echo 'Hello from entry point. The command is below:'
echo "$@"

exec "$@"