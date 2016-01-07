#!/bin/bash
set -e

if [ "$1" = 'passenger-start' ]; then
  echo 'Making sure the database is up to date...'
  cd /apps/ledger/app
  gosu ledger bundle exec rake db:migrate

  echo 'Starting passenger'
  passenger start --user ledger
elif [ "$1" = 'db-setup' ]; then
  echo 'doing db setup...'
  CREATE_ROLE_SQL="DO
  \$body\$
  BEGIN
     IF NOT EXISTS (
        SELECT *
        FROM   pg_catalog.pg_user
        WHERE  usename = 'ledger') THEN

        CREATE ROLE ledger LOGIN CREATEDB;
     END IF;
  END
  \$body\$;
  "
  psql -h ledgerdb -U postgres -c "${CREATE_ROLE_SQL}"
  cd /apps/ledger/app
  gosu ledger bundle exec rake db:create
  gosu ledger bundle exec rake db:setup
else
  exec "$@"
fi