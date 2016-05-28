#!/bin/bash
set -e

if [ "$1" = 'passenger-start' ]; then
  echo 'Making sure the database is up to date...'
  cd /apps/ledger/app
  gosu ledger bundle exec rake db:migrate

  echo 'Starting passenger'
  passenger start --user ledger -p 3000
elif [ "$1" = 'backburner' ]; then
  gosu ledger backburner
elif [ "$1" = 'db-setup' ]; then
  echo 'doing db setup...'
  cd /apps/ledger/app
  gosu ledger bundle exec rake db:setup
else
  exec "$@"
fi
