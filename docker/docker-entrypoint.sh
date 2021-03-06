#!/bin/bash
set -e

if [ "$1" = 'passenger-start' ]; then
  echo 'Making sure the database is up to date...'
  cd /apps/ledger/app
  bundle exec rake db:migrate

  echo 'Starting passenger'
  passenger start -p 3000
  
  # Riping out prefix added by passenger can be done like below
  # $ passenger start | sed -e 's/App [0-9]\+ \(stdout\|stderr\): //'
  # However this doesn't work well with non daemon mode and Ctrl + C
  #
  # I've also raised this: https://github.com/phusion/passenger/issues/1915
  
elif [ "$1" = 'backburner' ]; then
  backburner
elif [ "$1" = 'db-setup' ]; then
  echo 'doing db setup...'
  cd /apps/ledger/app
  bundle exec rake db:setup
else
  exec "$@"
fi
